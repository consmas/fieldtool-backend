require "csv"

module Trips
  class BulkImportService
    REQUIRED_HEADERS = %w[date trip_date].freeze

    attr_reader :file, :actor, :default_trip_date, :default_status, :dry_run, :default_driver_id, :default_vehicle_id

    def initialize(file:, actor:, default_trip_date: nil, default_status: "completed", dry_run: false, default_driver_id: nil, default_vehicle_id: nil)
      @file = file
      @actor = actor
      @default_trip_date = parse_date(default_trip_date)
      @default_status = normalize_status(default_status)
      @dry_run = ActiveModel::Type::Boolean.new.cast(dry_run)
      @default_driver_id = default_driver_id.presence&.to_i
      @default_vehicle_id = default_vehicle_id.presence&.to_i
    end

    def call
      rows = parse_rows
      validate_headers!(rows.headers)

      result = {
        total_rows: 0,
        created_count: 0,
        failed_count: 0,
        created_trip_ids: [],
        failures: []
      }

      rows.each_with_index do |row, index|
        row_number = index + 2
        next if skip_row?(row)

        result[:total_rows] += 1
        attrs = build_trip_attrs(row)

        if attrs[:driver_id].blank?
          result[:failed_count] += 1
          result[:failures] << failure(row_number, "Could not resolve driver (use driver_email or exact driver_name)")
          next
        end

        trip = Trip.new(attrs)
        trip.audit_actor = actor if trip.respond_to?(:audit_actor=)

        if dry_run
          if trip.valid?
            result[:created_count] += 1
          else
            result[:failed_count] += 1
            result[:failures] << failure(row_number, trip.errors.full_messages.to_sentence)
          end
          next
        end

        if trip.save
          TripEvent.create!(
            trip: trip,
            event_type: "trip_imported",
            message: "Trip imported from bulk upload",
            created_by: actor,
            data: { source: "csv_import", row_number: row_number }
          )

          result[:created_count] += 1
          result[:created_trip_ids] << trip.id
        else
          result[:failed_count] += 1
          result[:failures] << failure(row_number, trip.errors.full_messages.to_sentence)
        end
      rescue StandardError => e
        result[:failed_count] += 1
        result[:failures] << failure(row_number, e.message)
      end

      result
    end

    private

    def parse_rows
      content = if file.respond_to?(:read)
                  file.read
                else
                  File.read(file.to_s)
                end

      content = content.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
      CSV.parse(content, headers: true)
    ensure
      file.rewind if file.respond_to?(:rewind)
    end

    def validate_headers!(headers)
      normalized = headers.compact.map { |h| normalize_header(h) }
      return if (REQUIRED_HEADERS & normalized).any? && normalized.include?("destination")

      raise ArgumentError, "CSV must include at least Date/trip_date and Destination columns"
    end

    def build_trip_attrs(row)
      driver = resolve_driver(row)
      vehicle = resolve_vehicle(row)
      total_fee = parse_decimal(value(row, "total_fee"))
      base_fee = parse_decimal(value(row, "base_fee"))
      additional_fee = parse_decimal(value(row, "additional_fee"))
      additional_km = parse_decimal(value(row, "additional_km_travelled"))
      fuel_cost_per_litre = parse_decimal(value(row, "fuel_cost_per_litre"))
      stops = parse_integer(value(row, "no_of_stops"))
      trip_date = parse_date(value(row, "date", "trip_date"))

      {
        reference_code: value(row, "reference_code", "trip_id", "waybill_no", "waybill_number"),
        waybill_number: normalize_waybill(value(row, "waybill_number", "waybill_no", "reference_code")),
        driver_id: driver&.id,
        dispatcher_id: actor&.id,
        vehicle_id: vehicle&.id,
        trip_date: trip_date || default_trip_date || Date.current,
        pickup_location: value(row, "pickup_location", "origin", "loading_point"),
        dropoff_location: value(row, "dropoff_location", "destination", "delivery_point"),
        destination: value(row, "destination", "dropoff_location"),
        material_description: value(row, "cargo_type", "material_description", "cargo"),
        tonnage_load: parse_decimal(value(row, "tonnage_load", "weight_tons", "tonnage")),
        estimated_departure_time: parse_time(value(row, "estimated_departure_time", "departure_time")),
        estimated_arrival_time: parse_time(value(row, "estimated_arrival_time", "arrival_time")),
        status: normalize_status(value(row, "status")) || default_status,
        truck_reg_no: value(row, "truck_reg_no", "vehicle_reg", "registration_number"),
        client_name: value(row, "customer_name", "client_name"),
        road_expense_disbursed: total_fee || base_fee,
        road_expense_note: build_fee_note(base_fee: base_fee, additional_fee: additional_fee, additional_km: additional_km, fuel_cost_per_litre: fuel_cost_per_litre, stops: stops)
      }.compact
    end

    def resolve_driver(row)
      email = value(row, "driver_email")
      return User.find_by(email: email.downcase) if email.present?

      name = value(row, "driver_name")
      return User.find_by(id: default_driver_id) if name.blank? && default_driver_id.present?
      return nil if name.blank?

      User.where(role: :driver).where("LOWER(name) = ?", name.downcase).first
    end

    def resolve_vehicle(row)
      reg = value(row, "vehicle_reg", "truck_reg_no", "registration_number")
      return Vehicle.find_by(license_plate: reg) if reg.present?

      name = value(row, "vehicle_name", "truck_id")
      return Vehicle.find_by(id: default_vehicle_id) if name.blank? && default_vehicle_id.present?
      return nil if name.blank?

      Vehicle.where("LOWER(name) = ?", name.downcase).first
    end

    def value(row, *keys)
      keys.each do |key|
        cell = row[exact_header(row, key)]
        return cell.to_s.strip if cell.present?
      end
      nil
    end

    def exact_header(row, key)
      lookup = normalize_header(key)
      row.headers.find { |h| normalize_header(h) == lookup }
    end

    def normalize_header(value)
      value.to_s.strip.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/^_|_$/, "")
    end

    def parse_date(value)
      return nil if value.blank?

      Date.parse(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end

    def parse_time(value)
      return nil if value.blank?

      Time.zone.parse(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end

    def parse_decimal(value)
      return nil if value.blank?

      BigDecimal(value.to_s.gsub(/[^0-9.\-]/, ""))
    rescue ArgumentError
      nil
    end

    def normalize_status(value)
      status = value.to_s.presence&.downcase
      return nil if status.blank?
      return status if Trip.statuses.key?(status)

      mapped = {
        "in_transit" => "en_route",
        "on_route" => "en_route",
        "complete" => "completed"
      }[status]

      mapped if mapped && Trip.statuses.key?(mapped)
    end

    def normalize_waybill(value)
      waybill = value.to_s.strip
      return nil if waybill.blank? || waybill.casecmp("n/a").zero?

      waybill
    end

    def parse_integer(value)
      return nil if value.blank?

      value.to_s.gsub(/[^\d\-]/, "").to_i
    rescue StandardError
      nil
    end

    def build_fee_note(base_fee:, additional_fee:, additional_km:, fuel_cost_per_litre:, stops:)
      parts = []
      parts << "Base fee: #{base_fee.to_f.round(2)}" if base_fee.present?
      parts << "Additional fee: #{additional_fee.to_f.round(2)}" if additional_fee.present?
      parts << "Additional km: #{additional_km.to_f.round(2)}" if additional_km.present?
      parts << "Fuel cost per litre: #{fuel_cost_per_litre.to_f.round(2)}" if fuel_cost_per_litre.present?
      parts << "Stops: #{stops}" if stops.present?
      parts.join(" | ")
    end

    def skip_row?(row)
      values = row.to_h.values.map { |v| v.to_s.strip }
      return true if values.all?(&:blank?)

      row_date = value(row, "date", "trip_date").to_s.downcase
      customer = value(row, "customer_name", "client_name").to_s.downcase
      destination = value(row, "destination").to_s.downcase
      waybill = value(row, "waybill_no", "waybill_number").to_s.downcase

      return true if row_date.start_with?("total")
      return true if customer.start_with?("total")
      return true if customer.include?("downtime")
      return true if destination == "n/a" && waybill == "n/a"

      false
    end

    def failure(row_number, message)
      { row: row_number, error: message }
    end
  end
end

require "csv"

module Trips
  class BulkImportService
    REQUIRED_HEADERS = %w[driver_email driver_name].freeze

    attr_reader :file, :actor, :default_trip_date, :default_status, :dry_run

    def initialize(file:, actor:, default_trip_date: nil, default_status: "draft", dry_run: false)
      @file = file
      @actor = actor
      @default_trip_date = parse_date(default_trip_date)
      @default_status = normalize_status(default_status)
      @dry_run = ActiveModel::Type::Boolean.new.cast(dry_run)
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
      return if (REQUIRED_HEADERS & normalized).any?

      raise ArgumentError, "CSV must include either driver_email or driver_name column"
    end

    def build_trip_attrs(row)
      driver = resolve_driver(row)
      vehicle = resolve_vehicle(row)

      {
        reference_code: value(row, "reference_code", "trip_id", "waybill_no", "waybill_number"),
        waybill_number: value(row, "waybill_number", "waybill_no", "reference_code"),
        driver_id: driver&.id,
        dispatcher_id: actor&.id,
        vehicle_id: vehicle&.id,
        trip_date: parse_date(value(row, "trip_date", "date")) || default_trip_date || Date.current,
        pickup_location: value(row, "pickup_location", "origin", "loading_point"),
        dropoff_location: value(row, "dropoff_location", "destination", "delivery_point"),
        destination: value(row, "destination", "dropoff_location"),
        material_description: value(row, "cargo_type", "material_description", "cargo"),
        tonnage_load: parse_decimal(value(row, "tonnage_load", "weight_tons", "tonnage")),
        estimated_departure_time: parse_time(value(row, "estimated_departure_time", "departure_time")),
        estimated_arrival_time: parse_time(value(row, "estimated_arrival_time", "arrival_time")),
        status: normalize_status(value(row, "status")) || default_status,
        truck_reg_no: value(row, "truck_reg_no", "vehicle_reg", "registration_number")
      }.compact
    end

    def resolve_driver(row)
      email = value(row, "driver_email")
      return User.find_by(email: email.downcase) if email.present?

      name = value(row, "driver_name")
      return nil if name.blank?

      User.where(role: :driver).where("LOWER(name) = ?", name.downcase).first
    end

    def resolve_vehicle(row)
      reg = value(row, "vehicle_reg", "truck_reg_no", "registration_number")
      return Vehicle.find_by(license_plate: reg) if reg.present?

      name = value(row, "vehicle_name", "truck_id")
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

    def failure(row_number, message)
      { row: row_number, error: message }
    end
  end
end

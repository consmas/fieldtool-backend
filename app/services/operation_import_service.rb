require "csv"
require "json"
require "open3"
require "zip"

class OperationImportService
  def initialize(file_path:, file_name:, record_type:, reporting_month: nil)
    @file_path = file_path
    @file_name = file_name
    @record_type = record_type
    @reporting_month = reporting_month
  end

  def import!
    extension = File.extname(@file_name).downcase

    rows = case extension
    when ".csv"
      parse_csv
    when ".xlsx", ".xls"
      parse_excel
    else
      raise ArgumentError, "Unsupported file type"
    end

    OperationRecord.create!(rows)
  end

  private

  def parse_csv
    csv = CSV.read(@file_path, headers: true)
    rows = []

    csv.each do |row|
      payload = row.to_h
      next if skip_row?(payload)

      rows << build_payload(payload)
    end

    rows
  end

  def parse_excel
    return parse_excel_with_python if @file_name.to_s.downcase.end_with?(".xlsx") || @file_name.to_s.downcase.end_with?(".xls")

    raise ArgumentError, "Excel import is not available in this environment"
  end

  def parse_excel_with_python
    python_bin = ENV.fetch("PYTHON_BIN", "/Library/Developer/CommandLineTools/usr/bin/python3")
    script_path = Rails.root.join("lib", "tasks", "import_excel_workbook.py").to_s
    command = [python_bin, script_path, @file_path.to_s]
    output, status = Open3.capture2e(*command)
    raise ArgumentError, "Excel import failed: #{output}" unless status.success?

    rows = JSON.parse(output)
    rows.map do |row|
      row.merge(
        "record_type" => @record_type,
        "reporting_month" => @reporting_month,
        "source_file_name" => @file_name
      )
    end
  rescue JSON::ParserError, StandardError => e
    raise ArgumentError, "Excel import failed: #{e.message}"
  end

  def normalize_payload(payload)
    payload.each_with_object({}) do |(key, value), normalized|
      normalized[key.to_s.strip] = normalize_value(key, value)
    end
  end

  def normalize_value(key, value)
    return nil if value.blank?
    return excel_serial_to_date(value) if date_key?(key)

    value
  end

  def date_key?(key)
    key.to_s.downcase.match?(/date|month|reporting/i)
  end

  def excel_serial_to_date(value)
    return value if value.is_a?(Date)
    return value.to_date if value.is_a?(Time)

    numeric = value.to_s.strip
    return nil if numeric.blank?

    return Date.parse(numeric) if numeric.match?(/\d{4}-\d{2}-\d{2}/)

    serial = BigDecimal(numeric)
    Date.new(1899, 12, 30) + serial.to_i
  rescue StandardError
    Date.parse(value.to_s)
  rescue ArgumentError
    nil
  end

  def build_payload(payload)
    date_value = first_present(payload, ["Date", "Trip Start Date", "Reporting Month", "Trip Date"])
    revenue_value = first_present(payload, ["Expected Revenue", "Amount Due", "Amount Invoiced", "Total Fee", "Base Fee"])
    status_value = first_present(payload, ["Status", "Operational Status", "Fully Paid (Y/N)"])
    truck_value = first_present(payload, ["Truck ID", "Vehicle", "Truck", "Truck No.", "Truck Registration Number"])
    driver_value = first_present(payload, ["Driver Name", "Driver", "Driver Name / Code"])
    waybill_value = first_present(payload, ["Waybill No.", "Waybill Number", "Waybill"])
    destination_value = first_present(payload, ["Destination", "Drop Off Location", "Dropoff Location"])
    notes_value = first_present(payload, ["Remarks", "Notes", "Customer Name"])
    reporting_month_value = first_present(payload, ["Reporting Month", "Month"])
    customer_value = first_present(payload, ["Customer Name", "Client Name"])
    cargo_value = first_present(payload, ["Cargo Type", "Cargo", "Material Description"])
    origin_value = first_present(payload, ["Origin", "Pickup Location", "Loading Point"])
    total_fee_value = first_present(payload, ["Total Fee", "Amount Due", "Amount Invoiced"])
    base_fee_value = first_present(payload, ["Base Fee"])
    additional_fee_value = first_present(payload, ["Additional Fee"])
    additional_km_value = first_present(payload, ["Additional km Travelled"])
    fuel_cost_value = first_present(payload, ["Fuel Cost Per Litre*"])
    stops_value = first_present(payload, ["No. of Stops"])

    details = payload.except(*payload.keys.first(12)).compact
    details = details.merge(
      {
        "customer_name" => customer_value,
        "base_fee" => base_fee_value,
        "additional_fee" => additional_fee_value,
        "additional_km_travelled" => additional_km_value,
        "fuel_cost_per_litre" => fuel_cost_value,
        "no_of_stops" => stops_value
      }.compact
    )

    {
      record_type: @record_type,
      entry_date: parse_date(date_value),
      reporting_month: reporting_month_value || @reporting_month,
      trip_id: first_present(payload, ["Trip ID", "Trip Number", "Reference"]),
      waybill_no: waybill_value,
      truck_id: truck_value,
      driver_name: driver_value,
      cargo_type: cargo_value,
      origin: origin_value,
      destination: destination_value,
      expected_revenue: parse_decimal(revenue_value || total_fee_value),
      status: status_value || infer_status(payload),
      notes: [notes_value, customer_value, build_fee_note(base_fee_value, additional_fee_value, additional_km_value, fuel_cost_value, stops_value)].compact.join(" | "),
      details: details,
      source_file_name: @file_name
    }
  end

  def skip_row?(payload)
    return true if payload.blank?

    normalized = payload.values.compact.map { |value| value.to_s.strip }.join(" ")
    return true if normalized.blank?
    return true if normalized.match?(/\b(total|grand total)\b/i)
    return true if normalized.match?(/\bdowntime\b/i)
    return true if normalized.match?(/\bweekend\b/i)
    return true if normalized.match?(/\bholiday\b/i)
    return true if normalized.match?(/\bnot submitted\b/i)
    return true if normalized.match?(/\bn\/a\b/i) && payload["Waybill No."].to_s.strip.match?(/\bn\/a\b/i)

    false
  end

  def first_present(payload, keys)
    keys.each do |key|
      value = payload[key]
      return value if value.present?
    end
    nil
  end

  def infer_status(payload)
    total_fee = parse_decimal(first_present(payload, ["Total Fee", "Amount Due", "Amount Invoiced"]))
    return "Completed" if total_fee.to_f.positive?

    "Pending"
  end

  def parse_date(value)
    return nil if value.blank?
    return value if value.is_a?(Date)

    Date.parse(value.to_s)
  rescue ArgumentError
    nil
  end

  def parse_decimal(value)
    return 0 if value.blank?
    value.to_s.delete(",").to_d
  rescue StandardError
    0
  end

  def build_fee_note(base_fee, additional_fee, additional_km, fuel_cost, stops)
    parts = []
    parts << "Base fee: #{base_fee}" if base_fee.present?
    parts << "Additional fee: #{additional_fee}" if additional_fee.present?
    parts << "Additional km: #{additional_km}" if additional_km.present?
    parts << "Fuel cost per litre: #{fuel_cost}" if fuel_cost.present?
    parts << "Stops: #{stops}" if stops.present?
    parts.join(" | ")
  end
end

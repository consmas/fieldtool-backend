class OperationRecordsController < ApplicationController
  def index
    scope = OperationRecord.order(entry_date: :desc, created_at: :desc)
    scope = scope.by_type(params[:record_type]) if params[:record_type].present?
    scope = scope.for_month(params[:reporting_month]) if params[:reporting_month].present?
    scope = scope.for_truck(params[:truck_id]) if params[:truck_id].present?
    scope = scope.for_driver(params[:driver_name]) if params[:driver_name].present?

    render json: { records: scope.limit(200) }
  end

  def create
    record = OperationRecord.new(permitted_params)
    if record.save
      render json: { record: record }, status: :created
    else
      render json: { error: record.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def summary
    month = params[:reporting_month].presence || Date.current.strftime("%b %Y")
    records = OperationRecord.for_month(month).order(entry_date: :desc, created_at: :desc)

    render json: {
      reporting_month: month,
      total_records: records.count,
      total_revenue: records.sum(&:expected_revenue),
      by_status: records.group_by(&:status).transform_values(&:count),
      trucks: records.pluck(:truck_id).compact.uniq.count,
      drivers: records.pluck(:driver_name).compact.uniq.count
    }
  end

  def template
    csv = CSV.generate do |rows|
      rows << ["Date", "Trip ID", "Waybill No.", "Truck ID", "Driver Name", "Cargo Type", "Origin", "Destination", "Expected Revenue", "Status", "Remarks"]
      rows << ["2026-08-01", "TRIP-001", "WB-001", "GT-1295-26", "Bright Foekpe", "Steel", "Tsopoli", "Accra", "3750", "Operational", "Loaded"]
    end

    send_data csv, filename: "operations_template.csv", type: "text/csv"
  end

  def import
    file = params[:file]
    return render json: { error: "File is required" }, status: :unprocessable_entity unless file.present?

    tmp_path = Rails.root.join("tmp", "imports", "#{SecureRandom.hex(8)}_#{file.original_filename}")
    FileUtils.mkdir_p(tmp_path.dirname)
    File.binwrite(tmp_path, file.read)

    service = OperationImportService.new(
      file_path: tmp_path.to_s,
      file_name: file.original_filename,
      record_type: params[:record_type] || "trip",
      reporting_month: params[:reporting_month]
    )
    created = service.import!

    render json: { imported: created.count, records: created }, status: :created
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def permitted_params
    params.require(:operation_record).permit(
      :record_type,
      :entry_date,
      :reporting_month,
      :trip_id,
      :waybill_no,
      :truck_id,
      :driver_name,
      :cargo_type,
      :origin,
      :destination,
      :expected_revenue,
      :status,
      :notes,
      details: {}
    )
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
end

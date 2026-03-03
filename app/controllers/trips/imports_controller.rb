class Trips::ImportsController < ApplicationController
  def create
    authorize Trip, :create?

    file = params[:file]
    if file.blank?
      return render json: { error: "file is required (CSV format)" }, status: :bad_request
    end

    unless csv_file?(file)
      return render json: {
        error: "Unsupported file type. Upload CSV.",
        hint: "If your source is PDF, convert it to CSV first using these columns: driver_email or driver_name, vehicle_reg, trip_date, origin, destination, waybill_no"
      }, status: :unprocessable_entity
    end

    result = Trips::BulkImportService.new(
      file: file,
      actor: current_user,
      default_trip_date: params[:default_trip_date],
      default_status: params[:default_status],
      dry_run: params[:dry_run]
    ).call

    status = result[:failed_count].positive? ? :multi_status : :created
    render json: result, status: status
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def csv_file?(file)
    filename = file.respond_to?(:original_filename) ? file.original_filename.to_s : file.to_s
    mime = file.respond_to?(:content_type) ? file.content_type.to_s : ""

    filename.downcase.end_with?(".csv") || mime.in?(["text/csv", "application/csv", "application/vnd.ms-excel"])
  end
end

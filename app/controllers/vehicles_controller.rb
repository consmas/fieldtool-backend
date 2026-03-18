class VehiclesController < ApplicationController
  def index
    authorize Vehicle
    vehicles = policy_scope(Vehicle)
    render json: vehicles.map { |vehicle| vehicle_payload(vehicle) }
  end

  def show
    vehicle = Vehicle.find(params[:id])
    authorize vehicle
    render json: vehicle_payload(vehicle)
  end

  def create
    vehicle = Vehicle.new(vehicle_params)
    authorize vehicle
    insurance_file = params[:insurance_document].presence || params.dig(:vehicle, :insurance_document).presence
    vehicle.insurance_document.attach(insurance_file) if insurance_file.present?
    vehicle.save!
    sync_insurance_vehicle_document!(vehicle, insurance_file: insurance_file)
    render json: vehicle_payload(vehicle), status: :created
  end

  def update
    vehicle = Vehicle.find(params[:id])
    authorize vehicle
    vehicle.update!(vehicle_params)
    insurance_file = params[:insurance_document].presence || params.dig(:vehicle, :insurance_document).presence
    vehicle.insurance_document.attach(insurance_file) if insurance_file.present?
    sync_insurance_vehicle_document!(vehicle, insurance_file: insurance_file)
    render json: vehicle_payload(vehicle)
  end

  def destroy
    vehicle = Vehicle.find(params[:id])
    authorize vehicle
    vehicle.destroy!
    head :no_content
  end

  private

  def vehicle_params
    params.require(:vehicle).permit(
      :name, :kind, :license_plate, :vin, :notes, :active, :truck_type_capacity,
      :insurance_policy_number, :insurance_provider, :insurance_issued_at, :insurance_expires_at,
      :insurance_coverage_amount, :insurance_notes
    )
  end

  def vehicle_payload(vehicle)
    {
      id: vehicle.id,
      name: vehicle.name,
      kind: vehicle.kind,
      license_plate: vehicle.license_plate,
      vin: vehicle.vin,
      notes: vehicle.notes,
      active: vehicle.active,
      truck_type_capacity: vehicle.truck_type_capacity,
      insurance: {
        policy_number: vehicle.insurance_policy_number,
        provider: vehicle.insurance_provider,
        issued_at: vehicle.insurance_issued_at,
        expires_at: vehicle.insurance_expires_at,
        coverage_amount: vehicle.insurance_coverage_amount,
        notes: vehicle.insurance_notes,
        document_url: blob_url_for(vehicle.insurance_document)
      }
    }
  end

  def sync_insurance_vehicle_document!(vehicle, insurance_file:)
    doc = vehicle.vehicle_documents.where(document_type: "insurance").order(created_at: :desc).first_or_initialize
    doc.document_type = "insurance"
    doc.document_number = vehicle.insurance_policy_number
    doc.issued_at = vehicle.insurance_issued_at
    doc.expires_at = vehicle.insurance_expires_at
    doc.issuing_authority = vehicle.insurance_provider
    doc.status = "active" if doc.status.blank?
    doc.notify_before_days = 30 if doc.notify_before_days.blank?
    doc.notes = vehicle.insurance_notes if vehicle.insurance_notes.present?

    if insurance_file.present?
      doc.file.attach(insurance_file)
    elsif vehicle.insurance_document.attached? && !doc.file.attached?
      doc.file.attach(vehicle.insurance_document.blob)
    end

    doc.save! if doc.new_record? || doc.changed? || doc.file.attachment_changes.present?
  end
end

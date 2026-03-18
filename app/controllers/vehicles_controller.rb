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
    render json: vehicle_payload(vehicle), status: :created
  end

  def update
    vehicle = Vehicle.find(params[:id])
    authorize vehicle
    vehicle.update!(vehicle_params)
    insurance_file = params[:insurance_document].presence || params.dig(:vehicle, :insurance_document).presence
    vehicle.insurance_document.attach(insurance_file) if insurance_file.present?
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
end

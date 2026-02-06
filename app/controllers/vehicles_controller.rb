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
    vehicle.save!
    render json: vehicle_payload(vehicle), status: :created
  end

  def update
    vehicle = Vehicle.find(params[:id])
    authorize vehicle
    vehicle.update!(vehicle_params)
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
    params.require(:vehicle).permit(:name, :kind, :license_plate, :vin, :notes, :active)
  end

  def vehicle_payload(vehicle)
    {
      id: vehicle.id,
      name: vehicle.name,
      kind: vehicle.kind,
      license_plate: vehicle.license_plate,
      vin: vehicle.vin,
      notes: vehicle.notes,
      active: vehicle.active
    }
  end
end

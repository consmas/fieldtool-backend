class DestinationsController < ApplicationController
  def index
    authorize Destination
    destinations = policy_scope(Destination)
    render json: destinations.map { |destination| destination_payload(destination) }
  end

  def show
    destination = Destination.find(params[:id])
    authorize destination
    render json: destination_payload(destination)
  end

  def create
    destination = Destination.new(destination_params)
    authorize destination
    destination.save!
    render json: destination_payload(destination), status: :created
  end

  def update
    destination = Destination.find(params[:id])
    authorize destination
    destination.update!(destination_params)
    render json: destination_payload(destination)
  end

  def destroy
    destination = Destination.find(params[:id])
    authorize destination
    destination.destroy!
    head :no_content
  end

  def calculate
    destination = Destination.find(params[:id])
    authorize destination

    fuel_price_current = params.require(:fuel_price_current)
    additional_km = params[:additional_km] || 0

    result = DestinationRateCalculator.new(
      destination: destination,
      fuel_price_current: fuel_price_current,
      additional_km: additional_km
    ).call

    render json: result
  end

  private

  def destination_params
    params.require(:destination).permit(
      :name,
      :average_distance_km,
      :base_km,
      :base_trip_cost,
      :liters_per_km,
      :active
    )
  end

  def destination_payload(destination)
    {
      id: destination.id,
      name: destination.name,
      average_distance_km: destination.average_distance_km,
      base_km: destination.base_km,
      base_trip_cost: destination.base_trip_cost,
      liters_per_km: destination.liters_per_km,
      active: destination.active
    }
  end
end

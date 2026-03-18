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

    fuel_price = resolve_fuel_price(params[:fuel_price_current], params[:period])
    additional_km = params[:additional_km] || 0

    result = DestinationRateCalculator.new(
      destination: destination,
      fuel_price_current: fuel_price,
      additional_km: additional_km
    ).call

    render json: result
  end

  def preview_rate
    authorize Destination, :preview_rate?
    destination = Destination.new(preview_params)

    fuel_price = resolve_fuel_price(nil, params[:period])
    result = DestinationRateCalculator.new(
      destination: destination,
      fuel_price_current: fuel_price
    ).call

    render json: result.merge(fuel_price_used: fuel_price)
  end

  private

  def resolve_fuel_price(explicit_price, period_param)
    return explicit_price.to_d if explicit_price.present?

    price_date = period_param.present? ? Date.strptime(period_param, "%Y-%m") : Date.current
    FuelPrice.where("effective_at <= ?", price_date.end_of_month.end_of_day)
             .order(effective_at: :desc)
             .limit(1)
             .pick(:price_per_liter)
             .to_d
  end

  def current_fuel_price
    @current_fuel_price ||= FuelPrice.where("effective_at <= ?", Date.current.end_of_day)
                                     .order(effective_at: :desc)
                                     .limit(1)
                                     .pick(:price_per_liter)
                                     .to_d
  end

  def destination_params
    params.require(:destination).permit(
      :name,
      :average_distance_km,
      :base_km,
      :base_trip_cost,
      :kms_per_liter,
      :additional_provision_pct,
      :active
    )
  end

  def preview_params
    params.permit(
      :average_distance_km,
      :base_km,
      :base_trip_cost,
      :kms_per_liter,
      :additional_provision_pct
    )
  end

  def destination_payload(destination)
    rate_result = DestinationRateCalculator.new(
      destination: destination,
      fuel_price_current: current_fuel_price
    ).call

    {
      id: destination.id,
      name: destination.name,
      average_distance_km: destination.average_distance_km,
      base_km: destination.base_km,
      base_trip_cost: destination.base_trip_cost,
      kms_per_liter: destination.kms_per_liter,
      additional_provision_pct: destination.additional_provision_pct,
      active: destination.active,
      current_fuel_price: current_fuel_price,
      expected_rate: rate_result[:expected_rate]
    }
  end
end

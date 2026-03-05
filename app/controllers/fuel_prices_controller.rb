class FuelPricesController < ApplicationController
  def index
    authorize FuelPrice
    prices = policy_scope(FuelPrice).order(effective_at: :desc)
    render json: prices.map { |price| fuel_price_payload(price) }
  end

  def show
    price = FuelPrice.find(params[:id])
    authorize price
    render json: fuel_price_payload(price)
  end

  def create
    price = FuelPrice.new(fuel_price_params)
    authorize price
    price.updated_by = current_user
    price.save!
    render json: fuel_price_payload(price), status: :created
  end

  def update
    price = FuelPrice.find(params[:id])
    authorize price
    price.assign_attributes(fuel_price_params)
    price.updated_by = current_user
    price.save!
    render json: fuel_price_payload(price)
  end

  private

  def fuel_price_params
    params.require(:fuel_price).permit(:price_per_liter, :effective_at)
  end

  def fuel_price_payload(price)
    {
      id: price.id,
      price_per_liter: price.price_per_liter,
      effective_at: price.effective_at,
      updated_by_id: price.updated_by_id
    }
  end
end

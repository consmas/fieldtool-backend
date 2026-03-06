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
    enqueue_fuel_recalculation(price)
    render json: fuel_price_payload(price), status: :created
  end

  def update
    price = FuelPrice.find(params[:id])
    authorize price
    price.assign_attributes(fuel_price_params)
    price.updated_by = current_user
    price.save!
    enqueue_fuel_recalculation(price)
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

  def enqueue_fuel_recalculation(price)
    next_price = FuelPrice.where("effective_at > ?", price.effective_at).order(effective_at: :asc).first
    date_from = price.effective_at
    date_to = next_price ? (next_price.effective_at - 1.second) : Time.current.end_of_year

    Expenses::RecalculateFuelExpenseJob.perform_later(
      actor_id: current_user.id,
      date_from: date_from.iso8601,
      date_to: date_to.iso8601,
      target_statuses: %w[approved pending]
    )
  end
end

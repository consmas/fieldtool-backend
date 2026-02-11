class Trips::FuelAllocationsController < ApplicationController
  def update
    trip = Trip.find(params[:trip_id])
    authorize trip, :manage_logistics?

    trip.update!(
      fuel_allocated_litres: fuel_params[:fuel_allocated_litres],
      fuel_allocation_station: fuel_params[:fuel_allocation_station],
      fuel_allocation_payment_mode: fuel_params[:fuel_allocation_payment_mode],
      fuel_allocation_reference: fuel_params[:fuel_allocation_reference],
      fuel_allocation_note: fuel_params[:fuel_allocation_note],
      fuel_allocated_by: current_user,
      fuel_allocated_at: Time.current
    )

    TripEvent.create!(
      trip: trip,
      event_type: "fuel_allocated",
      message: "Fuel allocated",
      data: fuel_params.to_h,
      created_by: current_user
    )

    render json: {
      fuel_allocated_litres: trip.fuel_allocated_litres,
      fuel_allocation_station: trip.fuel_allocation_station,
      fuel_allocation_payment_mode: trip.fuel_allocation_payment_mode,
      fuel_allocation_reference: trip.fuel_allocation_reference,
      fuel_allocation_note: trip.fuel_allocation_note
    }
  end

  private

  def fuel_params
    params.require(:fuel_allocation).permit(
      :fuel_allocated_litres,
      :fuel_allocation_station,
      :fuel_allocation_payment_mode,
      :fuel_allocation_reference,
      :fuel_allocation_note
    )
  end
end

class Trips::StatusController < ApplicationController
  def create
    trip = Trip.find(params[:id])
    authorize trip, :change_status?

    new_status = params.require(:status)
    previous_status = trip.status

    if trip.transition_to!(new_status, by_user: current_user)
      TripEvent.create!(
        trip: trip,
        event_type: "status_changed",
        message: "Status changed to #{new_status}",
        created_by: current_user,
        data: { from: previous_status, to: new_status }
      )

      render json: { id: trip.id, status: trip.status }
    else
      render json: { error: trip.errors.full_messages.presence || ["Invalid status transition"] }, status: :unprocessable_entity
    end
  rescue ArgumentError => error
    render json: { error: error.message }, status: :unprocessable_entity
  end
end

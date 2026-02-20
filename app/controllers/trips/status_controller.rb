class Trips::StatusController < ApplicationController
  def create
    trip = Trip.find(params[:id])
    authorize trip, :change_status?

    new_status = params.require(:status)
    previous_status = trip.status

    if new_status.to_s == "en_route"
      compliance = ComplianceGateService.check_trip_readiness(trip)
      unless compliance[:ready]
        return render json: { error: "Trip failed compliance gate", compliance: compliance }, status: :unprocessable_entity
      end
    end

    set_audit_actor(trip, metadata: { source: "trips/status#create" })

    if trip.transition_to!(new_status, by_user: current_user)
      TripEvent.create!(
        trip: trip,
        event_type: "status_changed",
        message: "Status changed to #{new_status}",
        created_by: current_user,
        data: { from: previous_status, to: new_status }
      )

      Trips::TripStatusChangeJob.perform_later(trip.id, previous_status, trip.status, current_user.id)
      audit(action: "trip.status_changed", auditable: trip, changes: { status: { from: previous_status, to: trip.status } })

      render json: { id: trip.id, status: trip.status }
    else
      render json: { error: trip.errors.full_messages.presence || ["Invalid status transition"] }, status: :unprocessable_entity
    end
  rescue ArgumentError => error
    render json: { error: error.message }, status: :unprocessable_entity
  end
end

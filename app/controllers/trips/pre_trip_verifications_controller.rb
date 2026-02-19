class Trips::PreTripVerificationsController < ApplicationController
  def update
    trip = Trip.find(params[:trip_id])
    authorize trip, :manage_logistics?

    pre_trip = trip.pre_trip_inspection
    return render json: { error: ["Pre-trip inspection not found"] }, status: :not_found if pre_trip.nil?

    status = params[:status].to_s
    unless PreTripInspection.inspection_verification_statuses.key?(status)
      return render json: { error: ["Invalid status"] }, status: :unprocessable_entity
    end

    pre_trip.update!(
      inspection_verification_status: status,
      inspection_verification_note: params[:note],
      inspection_verified_by: current_user,
      inspection_verified_at: Time.current
    )

    TripEvent.create!(
      trip: trip,
      event_type: "pre_trip_verified",
      message: "Pre-trip inspection verified",
      data: { status: status, note: params[:note] },
      created_by: current_user
    )

    event_type = status == "rejected" ? "inspection.failed" : "inspection.verified"
    WebhookEventService.emit(
      event_type,
      resource: pre_trip,
      payload: Webhooks::InspectionWebhookSerializer.new(pre_trip).as_json,
      triggered_by: current_user
    )

    render json: { status: pre_trip.inspection_verification_status }
  end

  def confirm
    trip = Trip.find(params[:trip_id])
    authorize trip, :manage_logistics?

    pre_trip = trip.pre_trip_inspection
    return render json: { error: ["Pre-trip inspection not found"] }, status: :not_found if pre_trip.nil?

    pre_trip.update!(
      inspection_confirmed: true,
      inspection_confirmed_by: current_user,
      inspection_confirmed_at: Time.current
    )

    TripEvent.create!(
      trip: trip,
      event_type: "pre_trip_confirmed",
      message: "Pre-trip inspection confirmed",
      data: {},
      created_by: current_user
    )

    render json: { confirmed: pre_trip.inspection_confirmed }
  end
end

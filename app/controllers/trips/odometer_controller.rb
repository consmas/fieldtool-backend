class Trips::OdometerController < ApplicationController
  include Rails.application.routes.url_helpers
  def start
    trip = Trip.find(params[:id])
    authorize trip, :capture_odometer?

    if odometer_params[:photo].blank? || odometer_params[:value_km].blank?
      return render json: { error: "value_km and photo are required" }, status: :unprocessable_entity
    end

    trip.capture_start_odometer!(
      value_km: odometer_params.fetch(:value_km),
      photo: odometer_params[:photo],
      captured_by: current_user,
      captured_at: odometer_params[:captured_at] || Time.current,
      note: odometer_params[:note],
      lat: odometer_params[:lat],
      lng: odometer_params[:lng]
    )

    TripEvent.create!(
      trip: trip,
      event_type: "odometer_start_captured",
      message: "Start odometer captured",
      created_by: current_user,
      data: {
        value_km: trip.start_odometer_km,
        captured_at: trip.start_odometer_captured_at,
        note: trip.start_odometer_note,
        lat: trip.start_odometer_lat,
        lng: trip.start_odometer_lng
      }
    )

    render json: odometer_payload(trip, :start)
  end

  def end
    trip = Trip.find(params[:id])
    authorize trip, :capture_odometer?

    if odometer_params[:photo].blank? || odometer_params[:value_km].blank?
      return render json: { error: "value_km and photo are required" }, status: :unprocessable_entity
    end

    trip.capture_end_odometer!(
      value_km: odometer_params.fetch(:value_km),
      photo: odometer_params[:photo],
      captured_by: current_user,
      captured_at: odometer_params[:captured_at] || Time.current,
      note: odometer_params[:note],
      lat: odometer_params[:lat],
      lng: odometer_params[:lng]
    )

    TripEvent.create!(
      trip: trip,
      event_type: "odometer_end_captured",
      message: "End odometer captured",
      created_by: current_user,
      data: {
        value_km: trip.end_odometer_km,
        captured_at: trip.end_odometer_captured_at,
        note: trip.end_odometer_note,
        lat: trip.end_odometer_lat,
        lng: trip.end_odometer_lng
      }
    )

    render json: odometer_payload(trip, :end)
  end

  private

  def odometer_params
    params.require(:odometer).permit(:value_km, :photo, :captured_at, :note, :lat, :lng)
  end

  def odometer_payload(trip, which)
    if which == :start
      {
        trip_id: trip.id,
        start_odometer_km: trip.start_odometer_km,
        start_odometer_captured_at: trip.start_odometer_captured_at,
        start_odometer_captured_by_id: trip.start_odometer_captured_by_id,
        start_odometer_note: trip.start_odometer_note,
        start_odometer_lat: trip.start_odometer_lat,
        start_odometer_lng: trip.start_odometer_lng,
        start_odometer_photo_attached: trip.start_odometer_photo.attached?,
        start_odometer_photo_url: attachment_url(trip.start_odometer_photo)
      }
    else
      {
        trip_id: trip.id,
        end_odometer_km: trip.end_odometer_km,
        end_odometer_captured_at: trip.end_odometer_captured_at,
        end_odometer_captured_by_id: trip.end_odometer_captured_by_id,
        end_odometer_note: trip.end_odometer_note,
        end_odometer_lat: trip.end_odometer_lat,
        end_odometer_lng: trip.end_odometer_lng,
        end_odometer_photo_attached: trip.end_odometer_photo.attached?,
        end_odometer_photo_url: attachment_url(trip.end_odometer_photo)
      }
    end
  end

  def attachment_url(attachment)
    return nil unless attachment&.attached?

    Rails.application.routes.url_helpers.rails_blob_url(
      attachment,
      host: request.base_url,
      only_path: false
    )
  end
end

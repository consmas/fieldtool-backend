class Trips::LocationsController < ApplicationController
  def create
    trip = Trip.find(params[:trip_id])
    authorize trip, :record_location?

    ping = trip.location_pings.create!(location_params.merge(recorded_by: current_user))
    TripDistanceTracker.new(trip).add_ping!(ping)
    emit_batched_location_event(trip, ping)
    Trips::EtaRecalculationJob.perform_later(trip.id)

    render json: location_payload(ping), status: :created
  end

  def latest
    trip = Trip.find(params[:trip_id])
    authorize trip, :record_location?

    ping = trip.latest_location
    if ping
      render json: location_payload(ping)
    else
      render json: { error: "No location pings for this trip" }, status: :not_found
    end
  end

  private

  def location_params
    params.require(:location).permit(:lat, :lng, :speed, :heading, :recorded_at)
  end

  def location_payload(ping)
    {
      id: ping.id,
      trip_id: ping.trip_id,
      lat: ping.lat,
      lng: ping.lng,
      speed: ping.speed,
      heading: ping.heading,
      recorded_at: ping.recorded_at
    }
  end

  def emit_batched_location_event(trip, ping)
    cache_key = "webhook:trip:#{trip.id}:location_updated"
    return if Rails.cache.exist?(cache_key)

    Rails.cache.write(cache_key, true, expires_in: 5.minutes)
    WebhookEventService.emit(
      "trip.location_updated",
      resource: trip,
      payload: {
        trip_id: trip.id,
        latest_location: {
          lat: ping.lat,
          lng: ping.lng,
          speed: ping.speed,
          heading: ping.heading,
          recorded_at: ping.recorded_at
        }
      },
      triggered_by: current_user
    )
  end
end

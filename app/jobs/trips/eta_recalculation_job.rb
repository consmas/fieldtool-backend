module Trips
  class EtaRecalculationJob < ApplicationJob
    queue_as :default

    def perform(trip_id)
      trip = Trip.find_by(id: trip_id)
      return if trip.nil?

      latest = trip.latest_location
      return if latest.nil?

      # Placeholder ETA logic until routing service is integrated.
      eta_minutes = latest.speed.to_d.positive? ? ((trip.distance_km.to_d / latest.speed.to_d) * 60).round(1) : nil
      payload = Webhooks::TripWebhookSerializer.new(trip).as_json.merge(
        eta_minutes: eta_minutes,
        latest_location: {
          lat: latest.lat,
          lng: latest.lng,
          speed: latest.speed,
          recorded_at: latest.recorded_at
        }
      )

      WebhookEventService.emit("trip.eta_updated", resource: trip, payload: payload)
    end
  end
end

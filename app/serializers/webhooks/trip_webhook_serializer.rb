module Webhooks
  class TripWebhookSerializer
    def initialize(trip)
      @trip = trip
    end

    def as_json(*)
      {
        id: @trip.id,
        reference_code: @trip.reference_code,
        status: @trip.status,
        origin: @trip.pickup_location,
        destination: @trip.destination,
        started_at: @trip.status_changed_at,
        completed_at: @trip.completed_at,
        distance_km: @trip.distance_km,
        odometer_start: @trip.start_odometer_km,
        odometer_end: @trip.end_odometer_km,
        vehicle: {
          id: @trip.vehicle_id,
          registration: @trip.vehicle&.license_plate
        },
        driver: {
          id: @trip.driver_id,
          name: @trip.driver&.name
        }
      }
    end
  end
end

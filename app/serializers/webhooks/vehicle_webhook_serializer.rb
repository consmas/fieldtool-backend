module Webhooks
  class VehicleWebhookSerializer
    def initialize(vehicle)
      @vehicle = vehicle
    end

    def as_json(*)
      {
        id: @vehicle.id,
        name: @vehicle.name,
        license_plate: @vehicle.license_plate,
        truck_type_capacity: @vehicle.truck_type_capacity,
        active: @vehicle.active
      }
    end
  end
end

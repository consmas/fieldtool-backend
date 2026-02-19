module Webhooks
  class DeliveryWebhookSerializer
    def initialize(stop)
      @stop = stop
    end

    def as_json(*)
      {
        id: @stop.id,
        trip_id: @stop.trip_id,
        sequence: @stop.sequence,
        destination: @stop.destination,
        delivery_address: @stop.delivery_address,
        pod_type: @stop.pod_type,
        waybill_returned: @stop.waybill_returned,
        notes_incidents: @stop.notes_incidents
      }
    end
  end
end

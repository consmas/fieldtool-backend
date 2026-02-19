module Shipments
  class SyncFromTripService
    class << self
      def call(trip)
        shipment = Shipment.find_or_initialize_by(trip_id: trip.id)

        if shipment.new_record?
          shipment.client_id = trip.client_id
          shipment.tracking_number = "CM-#{Time.current.year}-#{trip.id.to_s.rjust(5, '0')}"
          shipment.tracking_link_token = SecureRandom.urlsafe_base64(32)
        end

        shipment.assign_attributes(
          reference_number: trip.client_reference,
          description: (trip.respond_to?(:description) ? trip.description : nil).presence || "Shipment for trip #{trip.id}",
          pickup_address: trip.loading_point,
          delivery_address: trip.destination,
          requested_pickup_date: trip.trip_date,
          requested_delivery_date: trip.trip_date,
          actual_pickup_at: trip.status.in?(%w[loaded en_route arrived offloaded completed]) ? (trip.status_changed_at || trip.updated_at) : shipment.actual_pickup_at,
          actual_delivery_at: trip.status == "completed" ? trip.completed_at : shipment.actual_delivery_at,
          status: client_status_for(trip.status),
          tracking_link_expires_at: ((trip.trip_date || Time.current).to_time + 7.days),
          pod_available: trip.client_rep_signature.attached? || trip.evidence.exists?
        )

        shipment.save!
        create_event!(shipment, trip)
        shipment
      end

      private

      def client_status_for(trip_status)
        Shipment::CLIENT_STATUS_MAP.fetch(trip_status.to_s, "booked")
      end

      def create_event!(shipment, trip)
        shipment.shipment_events.create!(
          event_type: "status_changed",
          title: "Shipment #{shipment.status.humanize}",
          description: "Trip status changed to #{trip.status}",
          location: trip.destination,
          is_public: true
        )
      end
    end
  end
end

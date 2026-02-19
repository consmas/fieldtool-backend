class Api::V1::PublicTrackingController < ActionController::API
  def show
    shipment = Shipment.tracking_active.find_by!(tracking_link_token: params[:tracking_link_token])

    latest_location = shipment.trip.latest_location
    render json: {
      tracking_number: shipment.tracking_number,
      status: shipment.status,
      origin_city: shipment.pickup_address,
      destination_city: shipment.delivery_address,
      eta: shipment.requested_delivery_date,
      current_location: (shipment.is_tracking_enabled? && latest_location) ? { lat: latest_location.lat, lng: latest_location.lng } : nil,
      events: shipment.shipment_events.where(is_public: true).order(created_at: :asc).map do |e|
        {
          event_type: e.event_type,
          title: e.title,
          description: e.description,
          created_at: e.created_at
        }
      end
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Tracking link invalid or expired" }, status: :not_found
  end
end

class Api::V1::Client::ShipmentsController < Api::V1::Client::BaseController
  def index
    scope = current_client.shipments.includes(:trip)
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(tracking_number: params[:tracking_number]) if params[:tracking_number].present?
    scope = scope.where(reference_number: params[:reference_number]) if params[:reference_number].present?
    scope = scope.where("created_at >= ?", parse_time(params[:date_from])) if parse_time(params[:date_from]).present?
    scope = scope.where("created_at <= ?", parse_time(params[:date_to])) if parse_time(params[:date_to]).present?

    render json: { data: scope.order(created_at: :desc).map { |shipment| base_payload(shipment) } }
  end

  def show
    shipment = current_client.shipments.find_by!(tracking_number: params[:tracking_number])

    render json: detail_payload(shipment)
  end

  def track
    shipment = current_client.shipments.find_by!(tracking_number: params[:tracking_number])
    return render json: { error: "Tracking disabled" }, status: :forbidden unless shipment.is_tracking_enabled?

    latest_location = shipment.trip.latest_location
    render json: {
      status: shipment.status,
      current_location: latest_location && { lat: latest_location.lat, lng: latest_location.lng, updated_at: latest_location.recorded_at },
      eta_minutes: nil,
      distance_remaining_km: nil,
      last_event: shipment.shipment_events.order(created_at: :desc).first&.title
    }
  end

  def events
    shipment = current_client.shipments.find_by!(tracking_number: params[:tracking_number])
    events = shipment.shipment_events.where(is_public: true).order(created_at: :asc)
    events = events.where(event_type: params[:event_type]) if params[:event_type].present?

    render json: { data: events.map { |e| event_payload(e) } }
  end

  def pod
    shipment = current_client.shipments.find_by!(tracking_number: params[:tracking_number])
    trip = shipment.trip

    render json: {
      tracking_number: shipment.tracking_number,
      pod_available: shipment.pod_available,
      documents: {
        client_rep_signature: blob_path(trip.client_rep_signature),
        end_odometer_photo: blob_path(trip.end_odometer_photo)
      }
    }
  end

  def feedback
    shipment = current_client.shipments.find_by!(tracking_number: params[:tracking_number])
    shipment.update!(client_rating: params.require(:rating), client_feedback: params[:feedback])

    render json: { tracking_number: shipment.tracking_number, client_rating: shipment.client_rating, client_feedback: shipment.client_feedback }
  end

  private

  def parse_time(value)
    return nil if value.blank?

    Time.zone.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end

  def base_payload(shipment)
    {
      tracking_number: shipment.tracking_number,
      reference_number: shipment.reference_number,
      status: shipment.status,
      origin: shipment.pickup_address,
      destination: shipment.delivery_address,
      requested_delivery_date: shipment.requested_delivery_date,
      eta: nil,
      driver_name: shipment.trip.driver&.name&.split&.first
    }
  end

  def detail_payload(shipment)
    {
      shipment: base_payload(shipment).merge(
        description: shipment.description,
        commodity_type: shipment.commodity_type,
        weight_kg: shipment.weight_kg,
        pieces_count: shipment.pieces_count,
        actual_pickup_at: shipment.actual_pickup_at,
        actual_delivery_at: shipment.actual_delivery_at,
        special_instructions: shipment.special_instructions,
        pod_available: shipment.pod_available,
        driver_first_name: shipment.trip.driver&.name&.split&.first,
        vehicle_type: shipment.trip.vehicle&.kind
      ),
      events: shipment.shipment_events.where(is_public: true).order(created_at: :asc).map { |e| event_payload(e) }
    }
  end

  def event_payload(event)
    {
      id: event.id,
      event_type: event.event_type,
      title: event.title,
      description: event.description,
      location: event.location,
      latitude: event.latitude,
      longitude: event.longitude,
      created_at: event.created_at
    }
  end

  def blob_path(attachment)
    return nil unless attachment.attached?

    Rails.application.routes.url_helpers.rails_blob_url(attachment, only_path: true)
  end
end

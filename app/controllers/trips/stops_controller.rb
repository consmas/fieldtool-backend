class Trips::StopsController < ApplicationController
  def index
    trip = Trip.find(params[:trip_id])
    authorize trip, :show?
    stops = trip.trip_stops.order(:sequence)
    render json: stops.map { |stop| stop_payload(stop) }
  end

  def show
    stop = TripStop.find(params[:id])
    authorize stop
    render json: stop_payload(stop)
  end

  def create
    trip = Trip.find(params[:trip_id])
    stop = trip.trip_stops.new(stop_params)
    authorize stop
    stop.save!
    render json: stop_payload(stop), status: :created
  end

  def update
    stop = TripStop.find(params[:id])
    authorize stop
    stop.update!(stop_params)

    if stop.waybill_returned == true
      WebhookEventService.emit(
        "delivery.completed",
        resource: stop,
        payload: Webhooks::DeliveryWebhookSerializer.new(stop).as_json,
        triggered_by: current_user
      )
    elsif stop.notes_incidents.present?
      WebhookEventService.emit(
        "delivery.failed",
        resource: stop,
        payload: Webhooks::DeliveryWebhookSerializer.new(stop).as_json,
        triggered_by: current_user
      )
    end

    render json: stop_payload(stop)
  end

  def destroy
    stop = TripStop.find(params[:id])
    authorize stop
    stop.destroy!
    head :no_content
  end

  private

  def stop_params
    params.require(:stop).permit(
      :sequence,
      :destination,
      :delivery_address,
      :tonnage_load,
      :waybill_number,
      :customer_contact_name,
      :customer_contact_phone,
      :special_instructions,
      :arrival_time_at_site,
      :pod_type,
      :waybill_returned,
      :notes_incidents
    )
  end

  def stop_payload(stop)
    {
      id: stop.id,
      trip_id: stop.trip_id,
      sequence: stop.sequence,
      destination: stop.destination,
      delivery_address: stop.delivery_address,
      tonnage_load: stop.tonnage_load,
      waybill_number: stop.waybill_number,
      customer_contact_name: stop.customer_contact_name,
      customer_contact_phone: stop.customer_contact_phone,
      special_instructions: stop.special_instructions,
      arrival_time_at_site: stop.arrival_time_at_site,
      pod_type: stop.pod_type,
      waybill_returned: stop.waybill_returned,
      notes_incidents: stop.notes_incidents,
      created_at: stop.created_at,
      updated_at: stop.updated_at
    }
  end
end

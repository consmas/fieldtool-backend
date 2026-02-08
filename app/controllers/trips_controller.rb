class TripsController < ApplicationController
  include Rails.application.routes.url_helpers

  def index
    authorize Trip
    trips = policy_scope(Trip).includes(:driver, :vehicle)
    trips = trips.where(status: params[:status]) if params[:status].present?

    render json: trips.map { |trip| trip_payload(trip, include_latest_location: false) }
  end

  def show
    trip = Trip.includes(:driver, :vehicle, :trip_events).find(params[:id])
    authorize trip

    render json: trip_payload(trip, include_latest_location: true, include_events: true)
  end

  def create
    trip = Trip.new(trip_params)
    authorize trip
    trip.save!

    TripEvent.create!(
      trip: trip,
      event_type: "trip_created",
      message: "Trip created",
      created_by: current_user,
      data: { status: trip.status }
    )

    render json: trip_payload(trip, include_latest_location: false), status: :created
  end

  def update
    trip = Trip.find(params[:id])
    authorize trip
    status_param = params.dig(:trip, :status)
    if status_param.present?
      previous_status = trip.status
      if trip.transition_to!(status_param, by_user: current_user)
        TripEvent.create!(
          trip: trip,
          event_type: "status_changed",
          message: "Status changed to #{status_param}",
          created_by: current_user,
          data: { from: previous_status, to: status_param }
        )
      else
        return render json: { error: trip.errors.full_messages.presence || ["Invalid status transition"] }, status: :unprocessable_entity
      end
    end

    trip.update!(trip_params)

    TripEvent.create!(
      trip: trip,
      event_type: "trip_updated",
      message: "Trip updated",
      created_by: current_user,
      data: { status: trip.status }
    )

    render json: trip_payload(trip, include_latest_location: false)
  rescue ArgumentError => error
    render json: { error: error.message }, status: :unprocessable_entity
  end

  def destroy
    trip = Trip.find(params[:id])
    authorize trip
    trip.destroy!
    head :no_content
  end

  private

  def trip_params
    permitted = if current_user&.driver?
      driver_trip_params
    else
      admin_trip_params
    end

    params.require(:trip).permit(*permitted)
  end

  def admin_trip_params
    [
      :reference_code,
      :driver_id,
      :dispatcher_id,
      :vehicle_id,
      :pickup_location,
      :dropoff_location,
      :pickup_notes,
      :dropoff_notes,
      :material_description,
      :waybill_number,
      :trip_date,
      :truck_reg_no,
      :driver_contact,
      :truck_type_capacity,
      :road_expense_disbursed,
      :road_expense_reference,
      :client_name,
      :destination,
      :delivery_address,
      :tonnage_load,
      :estimated_departure_time,
      :estimated_arrival_time,
      :customer_contact_name,
      :customer_contact_phone,
      :special_instructions,
      :arrival_time_at_site,
      :pod_type,
      :waybill_returned,
      :notes_incidents,
      :fuel_station_used,
      :fuel_payment_mode,
      :fuel_litres_filled,
      :fuel_receipt_no,
      :return_time,
      :vehicle_condition_post_trip,
      :post_trip_inspector_name,
      :scheduled_pickup_at,
      :scheduled_dropoff_at
    ]
  end

  def driver_trip_params
    [
      :arrival_time_at_site,
      :pod_type,
      :waybill_returned,
      :notes_incidents,
      :fuel_station_used,
      :fuel_payment_mode,
      :fuel_litres_filled,
      :fuel_receipt_no,
      :return_time,
      :vehicle_condition_post_trip,
      :post_trip_inspector_name
    ]
  end

  def trip_payload(trip, include_latest_location: false, include_events: false)
    payload = {
      id: trip.id,
      reference_code: trip.reference_code,
      status: trip.status,
      pickup_location: trip.pickup_location,
      dropoff_location: trip.dropoff_location,
      pickup_notes: trip.pickup_notes,
      dropoff_notes: trip.dropoff_notes,
      material_description: trip.material_description,
      waybill_number: trip.waybill_number,
      distance_km: trip.distance_km,
      distance_computed_at: trip.distance_computed_at,
      trip_date: trip.trip_date,
      truck_reg_no: trip.truck_reg_no,
      driver_contact: trip.driver_contact,
      truck_type_capacity: trip.truck_type_capacity,
      road_expense_disbursed: trip.road_expense_disbursed,
      road_expense_reference: trip.road_expense_reference,
      client_name: trip.client_name,
      destination: trip.destination,
      delivery_address: trip.delivery_address,
      tonnage_load: trip.tonnage_load,
      estimated_departure_time: trip.estimated_departure_time,
      estimated_arrival_time: trip.estimated_arrival_time,
      customer_contact_name: trip.customer_contact_name,
      customer_contact_phone: trip.customer_contact_phone,
      special_instructions: trip.special_instructions,
      arrival_time_at_site: trip.arrival_time_at_site,
      pod_type: trip.pod_type,
      waybill_returned: trip.waybill_returned,
      notes_incidents: trip.notes_incidents,
      fuel_station_used: trip.fuel_station_used,
      fuel_payment_mode: trip.fuel_payment_mode,
      fuel_litres_filled: trip.fuel_litres_filled,
      fuel_receipt_no: trip.fuel_receipt_no,
      return_time: trip.return_time,
      vehicle_condition_post_trip: trip.vehicle_condition_post_trip,
      post_trip_inspector_name: trip.post_trip_inspector_name,
      client_rep_signature_attached: trip.client_rep_signature.attached?,
      proof_of_fuelling_attached: trip.proof_of_fuelling.attached?,
      inspector_signature_attached: trip.inspector_signature.attached?,
      security_signature_attached: trip.security_signature.attached?,
      driver_signature_attached: trip.driver_signature.attached?,
      client_rep_signature_url: attachment_url(trip.client_rep_signature),
      proof_of_fuelling_url: attachment_url(trip.proof_of_fuelling),
      inspector_signature_url: attachment_url(trip.inspector_signature),
      security_signature_url: attachment_url(trip.security_signature),
      driver_signature_url: attachment_url(trip.driver_signature),
      scheduled_pickup_at: trip.scheduled_pickup_at,
      scheduled_dropoff_at: trip.scheduled_dropoff_at,
      driver: user_payload(trip.driver),
      dispatcher_id: trip.dispatcher_id,
      vehicle: vehicle_payload(trip.vehicle),
      start_odometer_km: trip.start_odometer_km,
      end_odometer_km: trip.end_odometer_km,
      start_odometer_captured_at: trip.start_odometer_captured_at,
      end_odometer_captured_at: trip.end_odometer_captured_at,
      start_odometer_captured_by_id: trip.start_odometer_captured_by_id,
      end_odometer_captured_by_id: trip.end_odometer_captured_by_id,
      start_odometer_note: trip.start_odometer_note,
      end_odometer_note: trip.end_odometer_note,
      start_odometer_lat: trip.start_odometer_lat,
      start_odometer_lng: trip.start_odometer_lng,
      end_odometer_lat: trip.end_odometer_lat,
      end_odometer_lng: trip.end_odometer_lng,
      start_odometer_photo_attached: trip.start_odometer_photo.attached?,
      end_odometer_photo_attached: trip.end_odometer_photo.attached?,
      start_odometer_photo_url: attachment_url(trip.start_odometer_photo),
      end_odometer_photo_url: attachment_url(trip.end_odometer_photo),
      status_changed_at: trip.status_changed_at,
      completed_at: trip.completed_at,
      cancelled_at: trip.cancelled_at
    }

    if include_latest_location
      latest = trip.latest_location
      payload[:latest_location] = latest_location_payload(latest) if latest
    end

    if include_events
      payload[:events] = trip.trip_events.order(created_at: :asc).map { |event| trip_event_payload(event) }
    end

    payload
  end

  def user_payload(user)
    return nil unless user

    {
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role
    }
  end

  def attachment_url(attachment)
    return nil unless attachment&.attached?

    Rails.application.routes.url_helpers.rails_blob_url(
      attachment,
      host: request.base_url,
      only_path: false
    )
  end

  def vehicle_payload(vehicle)
    return nil unless vehicle

    {
      id: vehicle.id,
      name: vehicle.name,
      kind: vehicle.kind,
      license_plate: vehicle.license_plate
    }
  end

  def latest_location_payload(ping)
    {
      id: ping.id,
      lat: ping.lat,
      lng: ping.lng,
      speed: ping.speed,
      heading: ping.heading,
      recorded_at: ping.recorded_at
    }
  end

  def trip_event_payload(event)
    {
      id: event.id,
      event_type: event.event_type,
      message: event.message,
      data: event.data,
      created_by_id: event.created_by_id,
      created_at: event.created_at
    }
  end
end

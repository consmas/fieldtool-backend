class TripsController < ApplicationController
  def index
    authorize Trip
    trips = policy_scope(Trip).includes(:driver, :truck, :trailer)
    trips = trips.where(status: params[:status]) if params[:status].present?

    render json: trips.map { |trip| trip_payload(trip, include_latest_location: false) }
  end

  def show
    trip = Trip.includes(:driver, :truck, :trailer, :trip_events).find(params[:id])
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
    params.require(:trip).permit(
      :reference_code,
      :driver_id,
      :dispatcher_id,
      :truck_id,
      :trailer_id,
      :pickup_location,
      :dropoff_location,
      :pickup_notes,
      :dropoff_notes,
      :material_description,
      :waybill_number,
      :scheduled_pickup_at,
      :scheduled_dropoff_at
    )
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
      scheduled_pickup_at: trip.scheduled_pickup_at,
      scheduled_dropoff_at: trip.scheduled_dropoff_at,
      driver: user_payload(trip.driver),
      dispatcher_id: trip.dispatcher_id,
      truck: vehicle_payload(trip.truck),
      trailer: vehicle_payload(trip.trailer),
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

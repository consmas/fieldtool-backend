class Trips::PreTripsController < ApplicationController
  def show
    trip = Trip.find(params[:trip_id])
    pre_trip = trip.pre_trip_inspection
    if pre_trip.nil?
      return render json: { error: "Pre-trip inspection not found" }, status: :not_found
    end

    authorize pre_trip
    render json: pre_trip_payload(pre_trip)
  end

  def create
    trip = Trip.find(params[:trip_id])
    pre_trip = trip.pre_trip_inspection || trip.build_pre_trip_inspection
    was_new = pre_trip.new_record?
    pre_trip.assign_attributes(pre_trip_params.except(:odometer_photo, :load_photo, :waybill_photo))
    pre_trip.captured_by ||= current_user
    pre_trip.odometer_captured_at ||= Time.current

    if params[:pre_trip]&.key?(:waybill_number)
      trip.update!(waybill_number: params[:pre_trip][:waybill_number])
    end

    attach_photos(pre_trip)

    authorize pre_trip
    pre_trip.save!

    TripEvent.create!(
      trip: trip,
      event_type: "pre_trip_completed",
      message: "Pre-trip inspection completed",
      created_by: current_user,
      data: {
        odometer_value_km: pre_trip.odometer_value_km,
        load_status: pre_trip.load_status,
        accepted: pre_trip.accepted
      }
    )

    render json: pre_trip_payload(pre_trip), status: (was_new ? :created : :ok)
  end

  def update
    trip = Trip.find(params[:trip_id])
    pre_trip = trip.pre_trip_inspection
    if pre_trip.nil?
      return render json: { error: "Pre-trip inspection not found" }, status: :not_found
    end

    authorize pre_trip

    pre_trip.assign_attributes(pre_trip_params.except(:odometer_photo, :load_photo, :waybill_photo))
    pre_trip.odometer_captured_at ||= Time.current
    attach_photos(pre_trip)
    pre_trip.save!

    TripEvent.create!(
      trip: trip,
      event_type: "pre_trip_updated",
      message: "Pre-trip inspection updated",
      created_by: current_user,
      data: {
        odometer_value_km: pre_trip.odometer_value_km,
        load_status: pre_trip.load_status,
        accepted: pre_trip.accepted
      }
    )

    render json: pre_trip_payload(pre_trip)
  end

  private

  def pre_trip_params
    params.require(:pre_trip).permit(
      :odometer_value_km,
      :odometer_captured_at,
      :odometer_lat,
      :odometer_lng,
      :brakes,
      :tyres,
      :lights,
      :mirrors,
      :horn,
      :fuel_sufficient,
      :load_area_ready,
      :load_status,
      :load_secured,
      :load_note,
      :accepted,
      :accepted_at,
      :waybill_number,
      :assistant_name,
      :assistant_phone,
      :fuel_level,
      :odometer_photo,
      :load_photo,
      :waybill_photo
    )
  end

  def attach_photos(pre_trip)
    odometer_photo = pre_trip_params[:odometer_photo]
    load_photo = pre_trip_params[:load_photo]
    waybill_photo = pre_trip_params[:waybill_photo]

    pre_trip.odometer_photo.attach(odometer_photo) if odometer_photo.present?
    pre_trip.load_photo.attach(load_photo) if load_photo.present?
    pre_trip.waybill_photo.attach(waybill_photo) if waybill_photo.present?
  end

  def pre_trip_payload(pre_trip)
    {
      id: pre_trip.id,
      trip_id: pre_trip.trip_id,
      captured_by_id: pre_trip.captured_by_id,
      odometer_value_km: pre_trip.odometer_value_km,
      odometer_captured_at: pre_trip.odometer_captured_at,
      odometer_lat: pre_trip.odometer_lat,
      odometer_lng: pre_trip.odometer_lng,
      brakes: pre_trip.brakes,
      tyres: pre_trip.tyres,
      lights: pre_trip.lights,
      mirrors: pre_trip.mirrors,
      horn: pre_trip.horn,
      fuel_sufficient: pre_trip.fuel_sufficient,
      load_area_ready: pre_trip.load_area_ready,
      load_status: pre_trip.load_status,
      load_secured: pre_trip.load_secured,
      load_note: pre_trip.load_note,
      accepted: pre_trip.accepted,
      accepted_at: pre_trip.accepted_at,
      waybill_number: pre_trip.waybill_number,
      assistant_name: pre_trip.assistant_name,
      assistant_phone: pre_trip.assistant_phone,
      fuel_level: pre_trip.fuel_level,
      odometer_photo_attached: pre_trip.odometer_photo.attached?,
      load_photo_attached: pre_trip.load_photo.attached?,
      waybill_photo_attached: pre_trip.waybill_photo.attached?,
      created_at: pre_trip.created_at,
      updated_at: pre_trip.updated_at
    }
  end
end

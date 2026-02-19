class FuelLogsController < ApplicationController
  def index
    authorize FuelLog, :index?

    scope = FuelLog.includes(:vehicle, :trip, :driver)
    scope = scope.where(vehicle_id: params[:vehicle_id]) if params[:vehicle_id].present?
    scope = scope.where(driver_id: params[:driver_id]) if params[:driver_id].present?
    scope = scope.where(trip_id: params[:trip_id]) if params[:trip_id].present?
    scope = scope.where(transaction_type: params[:transaction_type]) if params[:transaction_type].present?
    scope = scope.where(station_name: params[:station_name]) if params[:station_name].present?
    scope = scope.where("fueled_at >= ?", parse_time(params[:date_from])) if parse_time(params[:date_from]).present?
    scope = scope.where("fueled_at <= ?", parse_time(params[:date_to])) if parse_time(params[:date_to]).present?

    render json: { data: scope.order(fueled_at: :desc).map { |row| payload(row) } }
  end

  def create_for_vehicle
    vehicle = Vehicle.find(params[:vehicle_id])
    authorize FuelLog, :create?

    fuel_log = vehicle.fuel_logs.new(fuel_log_params)
    fuel_log.driver_id ||= params[:driver_id]
    fuel_log.recorded_by ||= current_user.id
    fuel_log.save!

    render json: payload(fuel_log), status: :created
  end

  def create_for_trip
    trip = Trip.find(params[:trip_id])
    authorize FuelLog, :create?

    fuel_log = FuelLog.new(fuel_log_params)
    fuel_log.trip_id = trip.id
    fuel_log.vehicle_id ||= trip.vehicle_id
    fuel_log.driver_id ||= trip.driver_id
    fuel_log.recorded_by ||= current_user.id
    fuel_log.save!

    render json: payload(fuel_log), status: :created
  end

  private

  def fuel_log_params
    params.require(:fuel_log).permit(
      :vehicle_id,
      :trip_id,
      :driver_id,
      :transaction_type,
      :fuel_type,
      :liters,
      :cost_per_liter,
      :odometer_reading,
      :station_name,
      :station_location,
      :latitude,
      :longitude,
      :fuel_card_reference,
      :receipt_number,
      :is_full_tank,
      :fueled_at,
      :recorded_by,
      :notes,
      metadata: {}
    )
  end

  def parse_time(value)
    return nil if value.blank?

    Time.zone.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end

  def payload(row)
    {
      id: row.id,
      vehicle_id: row.vehicle_id,
      trip_id: row.trip_id,
      driver_id: row.driver_id,
      transaction_type: row.transaction_type,
      fuel_type: row.fuel_type,
      liters: row.liters,
      cost_per_liter: row.cost_per_liter,
      total_cost: row.total_cost,
      odometer_reading: row.odometer_reading,
      station_name: row.station_name,
      station_location: row.station_location,
      latitude: row.latitude,
      longitude: row.longitude,
      fuel_card_reference: row.fuel_card_reference,
      receipt_number: row.receipt_number,
      is_full_tank: row.is_full_tank,
      fueled_at: row.fueled_at,
      recorded_by: row.recorded_by,
      notes: row.notes,
      metadata: row.metadata,
      created_at: row.created_at
    }
  end
end

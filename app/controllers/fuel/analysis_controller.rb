class Fuel::AnalysisController < ApplicationController
  def index
    authorize FuelAnalysisRecord, :index?

    scope = FuelAnalysisRecord.includes(:vehicle, :trip, :driver)
    scope = scope.where(vehicle_id: params[:vehicle_id]) if params[:vehicle_id].present?
    scope = scope.where(driver_id: params[:driver_id]) if params[:driver_id].present?
    scope = scope.where(is_anomaly: cast_bool(params[:is_anomaly])) unless params[:is_anomaly].nil?
    scope = scope.where(anomaly_severity: params[:anomaly_severity]) if params[:anomaly_severity].present?
    scope = scope.where(investigation_status: params[:investigation_status]) if params[:investigation_status].present?
    scope = scope.where("created_at >= ?", parse_time(params[:date_from])) if parse_time(params[:date_from]).present?
    scope = scope.where("created_at <= ?", parse_time(params[:date_to])) if parse_time(params[:date_to]).present?

    scope = case params[:sort]
            when "anomaly_score" then scope.order(anomaly_score: :desc)
            else scope.order(created_at: :desc)
            end

    render json: { data: scope.map { |row| payload(row) } }
  end

  def anomalies
    authorize FuelAnalysisRecord, :anomalies?

    rows = FuelAnalysisRecord.anomalies.where(investigation_status: ["pending", "investigating", nil])
    render json: {
      data: rows.group_by(&:anomaly_severity).transform_values { |items| items.map { |i| payload(i) } }
    }
  end

  def investigate
    record = FuelAnalysisRecord.find(params[:id])
    authorize record, :investigate?

    record.update!(
      investigation_status: params.require(:investigation_status),
      investigation_notes: params[:investigation_notes],
      investigated_by: current_user.id
    )

    render json: payload(record)
  end

  def vehicle
    authorize FuelAnalysisRecord, :show?

    records = FuelAnalysisRecord.where(vehicle_id: params[:vehicle_id]).order(created_at: :asc)
    render json: {
      vehicle_id: params[:vehicle_id].to_i,
      data: records.map do |row|
        {
          period: row.period_end || row.created_at,
          km_per_liter: row.actual_km_per_liter,
          variance_percent: row.variance_percent,
          is_anomaly: row.is_anomaly
        }
      end
    }
  end

  def driver
    authorize FuelAnalysisRecord, :show?

    records = FuelAnalysisRecord.where(driver_id: params[:driver_id]).order(created_at: :asc)
    render json: {
      driver_id: params[:driver_id].to_i,
      data: records.map do |row|
        {
          period: row.period_end || row.created_at,
          km_per_liter: row.actual_km_per_liter,
          variance_percent: row.variance_percent,
          is_anomaly: row.is_anomaly
        }
      end
    }
  end

  private

  def payload(row)
    {
      id: row.id,
      vehicle_id: row.vehicle_id,
      trip_id: row.trip_id,
      driver_id: row.driver_id,
      analysis_type: row.analysis_type,
      distance_km: row.distance_km,
      fuel_consumed_liters: row.fuel_consumed_liters,
      expected_consumption_liters: row.expected_consumption_liters,
      actual_km_per_liter: row.actual_km_per_liter,
      expected_km_per_liter: row.expected_km_per_liter,
      variance_percent: row.variance_percent,
      variance_liters: row.variance_liters,
      anomaly_score: row.anomaly_score,
      is_anomaly: row.is_anomaly,
      anomaly_type: row.anomaly_type,
      anomaly_severity: row.anomaly_severity,
      possible_causes: row.possible_causes,
      investigation_status: row.investigation_status,
      investigation_notes: row.investigation_notes,
      period_start: row.period_start,
      period_end: row.period_end,
      created_at: row.created_at
    }
  end

  def parse_time(value)
    return nil if value.blank?

    Time.zone.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end

  def cast_bool(value)
    ActiveModel::Type::Boolean.new.cast(value)
  end
end

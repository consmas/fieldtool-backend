class Reports::FuelController < ApplicationController
  def index
    authorize :fleet_report, :show?

    logs = filtered_fuel_logs
    analyses = filtered_analyses

    total_liters = logs.sum(:liters).to_d
    total_cost = logs.sum(:total_cost).to_d
    total_anomalies = analyses.anomalies.count
    waste_liters = analyses.anomalies.where("variance_liters > 0").sum(:variance_liters).to_d
    waste_cost = total_liters.positive? ? ((waste_liters / total_liters) * total_cost).round(2) : 0

    render json: {
      summary: {
        total_fuel_consumed_liters: total_liters,
        total_fuel_cost: total_cost,
        average_cost_per_liter: total_liters.positive? ? (total_cost / total_liters).round(2) : 0,
        fleet_average_km_per_liter: fleet_avg_km_per_liter,
        total_anomalies: total_anomalies,
        estimated_fuel_waste_liters: waste_liters,
        estimated_fuel_waste_cost: waste_cost
      },
      by_vehicle: vehicle_rows(logs, analyses),
      by_driver: driver_rows(analyses),
      by_month: month_rows(logs, analyses),
      worst_performers: performance_rows(limit: 5, order: :asc),
      best_performers: performance_rows(limit: 5, order: :desc)
    }
  end

  private

  def filtered_fuel_logs
    scope = FuelLog.all
    scope = scope.where(vehicle_id: params[:vehicle_id]) if params[:vehicle_id].present?
    scope = scope.where(driver_id: params[:driver_id]) if params[:driver_id].present?
    scope = scope.where("fueled_at >= ?", Time.zone.parse(params[:date_from])) if params[:date_from].present?
    scope = scope.where("fueled_at <= ?", Time.zone.parse(params[:date_to]).end_of_day) if params[:date_to].present?
    scope
  end

  def filtered_analyses
    scope = FuelAnalysisRecord.all
    scope = scope.where(vehicle_id: params[:vehicle_id]) if params[:vehicle_id].present?
    scope = scope.where(driver_id: params[:driver_id]) if params[:driver_id].present?
    scope = scope.where("created_at >= ?", Time.zone.parse(params[:date_from])) if params[:date_from].present?
    scope = scope.where("created_at <= ?", Time.zone.parse(params[:date_to]).end_of_day) if params[:date_to].present?
    scope
  rescue ArgumentError, TypeError
    scope
  end

  def fleet_avg_km_per_liter
    values = Vehicle.where.not(average_km_per_liter: nil).pluck(:average_km_per_liter).map(&:to_d)
    return 0 if values.empty?

    (values.sum / values.size).round(2)
  end

  def vehicle_rows(logs, analyses)
    Vehicle.all.map do |vehicle|
      vehicle_logs = logs.where(vehicle_id: vehicle.id)
      vehicle_analyses = analyses.where(vehicle_id: vehicle.id)
      {
        vehicle_id: vehicle.id,
        registration: vehicle.license_plate,
        km_per_liter: vehicle.average_km_per_liter,
        total_liters: vehicle_logs.sum(:liters).to_d,
        total_cost: vehicle_logs.sum(:total_cost).to_d,
        anomaly_count: vehicle_analyses.anomalies.count
      }
    end
  end

  def driver_rows(analyses)
    User.where(role: :driver).map do |driver|
      rows = analyses.where(driver_id: driver.id)
      {
        driver_id: driver.id,
        name: driver.name,
        avg_km_per_liter: rows.average(:actual_km_per_liter).to_d.round(2),
        trips_count: rows.where(analysis_type: "per_trip").count,
        anomalies: rows.anomalies.count
      }
    end
  end

  def month_rows(logs, analyses)
    logs.group("DATE_TRUNC('month', fueled_at)").sum(:liters).map do |month, liters|
      month_logs = logs.where("DATE_TRUNC('month', fueled_at) = ?", month)
      month_analyses = analyses.where("DATE_TRUNC('month', created_at) = ?", month)
      {
        month: month.strftime("%Y-%m"),
        liters: liters.to_d,
        cost: month_logs.sum(:total_cost).to_d,
        avg_km_per_liter: month_analyses.average(:actual_km_per_liter).to_d.round(2)
      }
    end
  end

  def performance_rows(limit:, order:)
    rows = Vehicle.where.not(average_km_per_liter: nil).order(average_km_per_liter: order).limit(limit)
    rows.map do |vehicle|
      {
        vehicle_id: vehicle.id,
        registration: vehicle.license_plate,
        average_km_per_liter: vehicle.average_km_per_liter
      }
    end
  end
end

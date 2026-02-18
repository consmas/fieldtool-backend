class Reports::DashboardController < ApplicationController
  def overview
    authorize :fleet_report, :show?

    trips = filtered_trips
    expenses = filtered_expenses
    total_distance_km = trips.sum(:distance_km).to_d
    total_expense = expenses.sum(:amount).to_d

    render json: {
      period: report_period_payload,
      trips: {
        total: trips.count,
        draft: trips.where(status: :draft).count,
        assigned: trips.where(status: :assigned).count,
        en_route: trips.where(status: :en_route).count,
        completed: trips.where(status: :completed).count,
        cancelled: trips.where(status: :cancelled).count,
        completion_rate_pct: percentage(trips.where(status: :completed).count, trips.count),
        total_distance_km: total_distance_km
      },
      expenses: {
        total: total_expense,
        fuel_total: expenses.where(category: :fuel).sum(:amount).to_d,
        road_fee_total: expenses.where(category: :road_fee).sum(:amount).to_d,
        maintenance_total: expenses.where(category: :maintenance).sum(:amount).to_d,
        repair_total: expenses.where(category: :repair).sum(:amount).to_d,
        emergency_total: expenses.where(category: :emergency).sum(:amount).to_d,
        paid_total: expenses.where(status: :paid).sum(:amount).to_d,
        pending_total: expenses.where(status: [:pending, :approved]).sum(:amount).to_d
      },
      efficiency: {
        cost_per_km: total_distance_km.positive? ? (total_expense / total_distance_km).round(2) : 0
      }
    }
  end

  def trips
    authorize :fleet_report, :show?
    trips = filtered_trips

    render json: {
      period: report_period_payload,
      totals: {
        total: trips.count,
        by_status: enum_group_to_names(Trip, :status, trips.group(:status).count)
      },
      timeline: {
        created_daily: trips.group("DATE(created_at)").count,
        completed_daily: trips.where.not(completed_at: nil).group("DATE(completed_at)").count
      },
      quality: {
        with_incidents: trips.where.not(notes_incidents: [nil, ""]).count,
        incident_rate_pct: percentage(trips.where.not(notes_incidents: [nil, ""]).count, trips.count)
      },
      destination_breakdown: trips.group(:destination).count.sort_by { |_name, count| -count }.first(20).to_h
    }
  end

  def expenses
    authorize :fleet_report, :show?
    expenses = filtered_expenses

    render json: {
      period: report_period_payload,
      totals: {
        total: expenses.sum(:amount).to_d,
        by_category: enum_group_to_names(ExpenseEntry, :category, expenses.group(:category).sum(:amount)),
        by_status: enum_group_to_names(ExpenseEntry, :status, expenses.group(:status).sum(:amount))
      },
      timeline: {
        daily_total: expenses.group("DATE(expense_date)").sum(:amount)
      },
      dimensions: {
        by_vehicle: expenses.group(:vehicle_id).sum(:amount),
        by_driver: expenses.group(:driver_id).sum(:amount),
        by_trip: expenses.group(:trip_id).sum(:amount)
      }
    }
  end

  def drivers
    authorize :fleet_report, :show?
    drivers = User.where(role: :driver)
    drivers = drivers.where(id: params[:driver_id]) if params[:driver_id].present?

    trips_scope = filtered_trips
    expenses_scope = filtered_expenses

    payload = drivers.map do |driver|
      driver_trips = trips_scope.where(driver_id: driver.id)
      completed = driver_trips.where(status: :completed).count
      total = driver_trips.count
      {
        driver_id: driver.id,
        name: driver.name,
        email: driver.email,
        trips_total: total,
        trips_completed: completed,
        completion_rate_pct: percentage(completed, total),
        distance_km_total: driver_trips.sum(:distance_km).to_d,
        incidents_count: driver_trips.where.not(notes_incidents: [nil, ""]).count,
        expenses_total: expenses_scope.where(driver_id: driver.id).sum(:amount).to_d,
        unpaid_expenses_total: expenses_scope.where(driver_id: driver.id, status: [:pending, :approved]).sum(:amount).to_d
      }
    end

    render json: { period: report_period_payload, data: payload }
  end

  def vehicles
    authorize :fleet_report, :show?
    vehicles = Vehicle.all
    vehicles = vehicles.where(id: params[:vehicle_id]) if params[:vehicle_id].present?

    trips_scope = filtered_trips
    expenses_scope = filtered_expenses

    payload = vehicles.map do |vehicle|
      vehicle_trips = trips_scope.where(vehicle_id: vehicle.id)
      {
        vehicle_id: vehicle.id,
        name: vehicle.name,
        license_plate: vehicle.license_plate,
        trips_total: vehicle_trips.count,
        trips_completed: vehicle_trips.where(status: :completed).count,
        distance_km_total: vehicle_trips.sum(:distance_km).to_d,
        fuel_litres_total: vehicle_trips.sum(:fuel_litres_filled).to_d,
        expenses_total: expenses_scope.where(vehicle_id: vehicle.id).sum(:amount).to_d,
        maintenance_total: expenses_scope.where(vehicle_id: vehicle.id, category: [:maintenance, :repair]).sum(:amount).to_d
      }
    end

    render json: { period: report_period_payload, data: payload }
  end

  private

  def filtered_trips
    scope = Trip.all
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(driver_id: params[:driver_id]) if params[:driver_id].present?
    scope = scope.where(vehicle_id: params[:vehicle_id]) if params[:vehicle_id].present?

    if date_from.present?
      scope = scope.where("trip_date >= ? OR (trip_date IS NULL AND created_at >= ?)", date_from.to_date, date_from)
    end
    if date_to.present?
      scope = scope.where("trip_date <= ? OR (trip_date IS NULL AND created_at <= ?)", date_to.to_date, date_to.end_of_day)
    end

    scope
  end

  def filtered_expenses
    scope = ExpenseEntry.active
    scope = scope.where(category: params[:category]) if params[:category].present?
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(trip_id: params[:trip_id]) if params[:trip_id].present?
    scope = scope.where(vehicle_id: params[:vehicle_id]) if params[:vehicle_id].present?
    scope = scope.where(driver_id: params[:driver_id]) if params[:driver_id].present?
    scope = scope.where("expense_date >= ?", date_from) if date_from.present?
    scope = scope.where("expense_date <= ?", date_to.end_of_day) if date_to.present?
    scope
  end

  def report_period_payload
    {
      date_from: date_from,
      date_to: date_to
    }
  end

  def date_from
    @date_from ||= parse_time(params[:date_from])
  end

  def date_to
    @date_to ||= parse_time(params[:date_to])
  end

  def parse_time(value)
    return nil if value.blank?

    Time.zone.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end

  def percentage(part, whole)
    return 0 if whole.to_i <= 0

    ((part.to_d / whole.to_d) * 100).round(2)
  end

  def enum_group_to_names(model, enum_attr, grouped_hash)
    mapping = model.public_send(enum_attr.to_s.pluralize)
    grouped_hash.each_with_object({}) do |(key, value), result|
      enum_key = mapping.key(key) || mapping.key(key.to_s) || mapping.key(key.to_i) || key
      result[enum_key] = value
    end
  end
end

class Reports::MaintenanceController < ApplicationController
  def index
    authorize :fleet_report, :show?

    work_orders = scoped_work_orders
    completed = work_orders.where(status: "completed")

    avg_completion_hours = completed.where.not(started_at: nil, completed_at: nil)
                                    .average("EXTRACT(EPOCH FROM (completed_at - started_at)) / 3600.0")
                                    .to_d

    render json: {
      period: report_period,
      totals: {
        total_maintenance_cost: completed.sum(:actual_cost).to_d,
        overdue_items_count: work_orders.where.not(status: %w[completed cancelled]).where("scheduled_date < ?", Date.current).count,
        average_completion_hours: avg_completion_hours.round(2)
      },
      breakdowns: {
        by_work_order_type: completed.group(:work_order_type).sum(:actual_cost),
        by_vehicle: completed.group(:vehicle_id).sum(:actual_cost),
        preventive_vs_corrective_ratio: preventive_corrective_ratio(completed),
        downtime_hours_by_vehicle: completed.group(:vehicle_id).sum(:downtime_hours),
        vendor_spend_summary: completed.group(:vendor_id).sum(:actual_cost)
      },
      top_spending_vehicles: completed.group(:vehicle_id).sum(:actual_cost).sort_by { |_id, amount| -amount.to_d }.first(10).to_h
    }
  end

  def vehicle_history
    authorize :fleet_report, :show?

    vehicle = Vehicle.find(params[:id])
    work_orders = vehicle.work_orders.order(created_at: :asc)

    render json: {
      vehicle: { id: vehicle.id, name: vehicle.name, license_plate: vehicle.license_plate },
      maintenance_timeline: work_orders.map do |wo|
        {
          work_order_number: wo.work_order_number,
          title: wo.title,
          status: wo.status,
          type: wo.work_order_type,
          priority: wo.priority,
          scheduled_date: wo.scheduled_date,
          completed_at: wo.completed_at,
          actual_cost: wo.actual_cost,
          downtime_hours: wo.downtime_hours
        }
      end,
      document_status: vehicle.vehicle_documents.order(expires_at: :asc).map do |doc|
        {
          id: doc.id,
          document_type: doc.document_type,
          status: doc.status,
          expires_at: doc.expires_at,
          days_until_expiry: doc.days_until_expiry
        }
      end,
      tco_total: ExpenseEntry.active.where(vehicle_id: vehicle.id).sum(:amount).to_d,
      predicted_next_maintenance: vehicle.maintenance_schedules.active.order(next_due_at: :asc, next_due_km: :asc).limit(5).map do |schedule|
        {
          id: schedule.id,
          name: schedule.name,
          next_due_at: schedule.next_due_at,
          next_due_km: schedule.next_due_km,
          is_overdue: schedule.overdue?
        }
      end
    }
  end

  private

  def scoped_work_orders
    scope = WorkOrder.includes(:vehicle)
    scope = scope.where("created_at >= ?", date_from.beginning_of_day) if date_from.present?
    scope = scope.where("created_at <= ?", date_to.end_of_day) if date_to.present?
    scope
  end

  def report_period
    { date_from: date_from, date_to: date_to }
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

  def preventive_corrective_ratio(completed)
    preventive = completed.where(work_order_type: "preventive").count
    corrective = completed.where(work_order_type: "corrective").count
    return nil if corrective.zero?

    (preventive.to_d / corrective.to_d).round(2)
  end
end

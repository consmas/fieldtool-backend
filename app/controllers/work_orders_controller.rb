class WorkOrdersController < ApplicationController
  def index
    authorize WorkOrder, :index?

    scope = WorkOrder.includes(:vehicle, :vendor, :parts)
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(vehicle_id: params[:vehicle_id]) if params[:vehicle_id].present?
    scope = scope.where(work_order_type: params[:work_order_type]) if params[:work_order_type].present?
    scope = scope.where(priority: params[:priority]) if params[:priority].present?
    scope = scope.where(assigned_to: params[:assigned_to]) if params[:assigned_to].present?
    scope = scope.where(vendor_id: params[:vendor_id]) if params[:vendor_id].present?
    from_date = parse_date(params[:date_from])
    to_date = parse_date(params[:date_to])
    scope = scope.where("scheduled_date >= ?", from_date) if from_date.present?
    scope = scope.where("scheduled_date <= ?", to_date) if to_date.present?
    scope = scope.where("scheduled_date < ?", Date.current).where.not(status: %w[completed cancelled]) if cast_bool(params[:overdue])

    scope = case params[:sort]
            when "priority" then scope.order(Arel.sql(priority_sort_sql))
            when "scheduled_date" then scope.order(scheduled_date: :asc)
            else scope.order(created_at: :desc)
            end

    page = params[:page].to_i.positive? ? params[:page].to_i : 1
    per_page = [params[:per_page].to_i.positive? ? params[:per_page].to_i : 25, 100].min
    total = scope.count
    records = scope.offset((page - 1) * per_page).limit(per_page)

    render json: {
      data: records.map { |wo| work_order_payload(wo) },
      meta: { page: page, per_page: per_page, total: total }
    }
  end

  def create
    authorize WorkOrder, :create?

    attrs = normalized_work_order_params
    work_order = WorkOrder.new(attrs)
    work_order.title = default_title_for(work_order.vehicle_id) if work_order.title.blank?
    work_order.reporter = current_user if work_order.has_attribute?(:reported_by)
    work_order.reported_at ||= Time.current if work_order.has_attribute?(:reported_at)
    work_order.save!
    NotificationService.notify(
      notification_type: "maintenance.work_order_created",
      recipients: ["admin", "supervisor"],
      actor: current_user,
      notifiable: work_order,
      data: {
        wo_number: work_order.work_order_number,
        vehicle_reg: work_order.vehicle&.license_plate,
        title: work_order.title
      }
    )

    render json: work_order_payload(work_order), status: :created
  end

  def show
    work_order = WorkOrder.includes(:vehicle, :vendor, :parts, comments: :user).find(params[:id])
    authorize work_order, :show?

    render json: work_order_payload(work_order, include_timeline: true)
  end

  def update
    work_order = WorkOrder.find(params[:id])
    authorize work_order, :update?

    immutable = work_order.status.in?(%w[completed cancelled])
    attrs = immutable ? normalized_work_order_params.slice(:notes, :resolution_notes) : normalized_work_order_params
    work_order.update!(attrs)

    render json: work_order_payload(work_order)
  end

  def update_status
    work_order = WorkOrder.find(params[:id])
    authorize work_order, :status?

    work_order.transition_status!(
      new_status: params.require(:status),
      actor: current_user,
      notes: params[:notes]
    )

    if work_order.status == "completed"
      WorkOrders::CompletionJob.perform_later(work_order.id, current_user.id)
    end

    render json: work_order_payload(work_order.reload)
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def by_vehicle
    authorize WorkOrder, :index?

    vehicle = Vehicle.find(params[:vehicle_id])
    page = params[:page].to_i.positive? ? params[:page].to_i : 1
    per_page = [params[:per_page].to_i.positive? ? params[:per_page].to_i : 25, 100].min
    scope = vehicle.work_orders.order(created_at: :desc)

    render json: {
      data: scope.offset((page - 1) * per_page).limit(per_page).map { |wo| work_order_payload(wo) },
      meta: { page: page, per_page: per_page, total: scope.count }
    }
  end

  def summary
    authorize WorkOrder, :summary?

    scope = WorkOrder.all
    month_start = Date.current.beginning_of_month
    quarter_start = Date.current.beginning_of_quarter

    completed = scope.where(status: "completed").where.not(completed_at: nil)
    average_completion_hours = completed.where.not(started_at: nil).average("EXTRACT(EPOCH FROM (completed_at - started_at)) / 3600.0").to_d.round(2)

    render json: {
      open_by_priority: scope.where(status: %w[draft open in_progress on_hold]).group(:priority).count,
      average_completion_hours: average_completion_hours,
      spend_this_month: completed.where(completed_at: month_start.beginning_of_day..Time.current).sum(:actual_cost).to_d,
      spend_this_quarter: completed.where(completed_at: quarter_start.beginning_of_day..Time.current).sum(:actual_cost).to_d,
      vehicles_in_maintenance: scope.where(status: "in_progress").distinct.count(:vehicle_id),
      overdue_count: scope.where.not(status: %w[completed cancelled]).where("scheduled_date < ?", Date.current).count
    }
  end

  private

  def work_order_params
    params.require(:work_order).permit(
      :vehicle_id,
      :maintenance_schedule_id,
      :title,
      :description,
      :status,
      :type,
      :work_order_type,
      :priority,
      :assigned_to,
      :assigned_to_type,
      :vendor_id,
      :scheduled_date,
      :estimated_cost,
      :actual_cost,
      :labor_hours,
      :labor_cost,
      :parts_cost,
      :notes,
      :resolution_notes,
      :failure_reason,
      metadata: {}
    )
  end

  def normalized_work_order_params
    attrs = work_order_params.to_h.with_indifferent_access
    attrs[:work_order_type] = attrs.delete(:type) if attrs[:work_order_type].blank? && attrs[:type].present?
    attrs
  end

  def default_title_for(vehicle_id)
    vehicle = Vehicle.find_by(id: vehicle_id)
    return "Maintenance Work Order" if vehicle.nil?

    "Maintenance - #{vehicle.license_plate.presence || vehicle.name}"
  end

  def work_order_payload(wo, include_timeline: false)
    payload = {
      id: wo.id,
      work_order_number: wo.work_order_number,
      vehicle_id: wo.vehicle_id,
      vehicle: { id: wo.vehicle.id, name: wo.vehicle.name, license_plate: wo.vehicle.license_plate },
      maintenance_schedule_id: wo.maintenance_schedule_id,
      title: wo.title,
      description: wo.description,
      work_order_type: wo.work_order_type,
      status: wo.status,
      priority: wo.priority,
      assigned_to: wo.assigned_to,
      assigned_to_type: wo.assigned_to_type,
      vendor: wo.vendor && { id: wo.vendor.id, name: wo.vendor.name },
      reported_by: (wo.has_attribute?(:reported_by) ? wo[:reported_by] : nil),
      reported_at: (wo.has_attribute?(:reported_at) ? wo[:reported_at] : nil),
      scheduled_date: wo.scheduled_date,
      started_at: wo.started_at,
      completed_at: wo.completed_at,
      odometer_at_creation: wo.odometer_at_creation,
      estimated_cost: wo.estimated_cost,
      actual_cost: wo.actual_cost,
      labor_hours: wo.labor_hours,
      labor_cost: wo.labor_cost,
      parts_cost: wo.parts_cost,
      downtime_hours: wo.downtime_hours,
      failure_reason: wo.failure_reason,
      notes: wo.notes,
      resolution_notes: wo.resolution_notes,
      expense_entry_id: wo.expense_entry_id,
      parts_summary: {
        count: wo.parts.size,
        total_cost: wo.parts.sum(:total_cost).to_d
      },
      created_at: wo.created_at,
      updated_at: wo.updated_at
    }

    if include_timeline
      payload[:parts] = wo.parts.order(created_at: :asc).map do |part|
        {
          id: part.id,
          part_name: part.part_name,
          part_number: part.part_number,
          quantity: part.quantity,
          unit: part.unit,
          unit_cost: part.unit_cost,
          total_cost: part.total_cost,
          supplier: part.supplier,
          notes: part.notes
        }
      end
      payload[:comments] = wo.comments.order(created_at: :asc).map do |comment|
        {
          id: comment.id,
          comment: comment.comment,
          comment_type: comment.comment_type,
          metadata: comment.metadata,
          user: { id: comment.user_id, name: comment.user&.name },
          created_at: comment.created_at
        }
      end
    end

    payload
  end

  def parse_date(value)
    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end

  def cast_bool(value)
    ActiveModel::Type::Boolean.new.cast(value)
  end

  def priority_sort_sql
    <<~SQL.squish
      CASE priority
        WHEN 'critical' THEN 0
        WHEN 'high' THEN 1
        WHEN 'medium' THEN 2
        WHEN 'low' THEN 3
        ELSE 4
      END ASC,
      created_at DESC
    SQL
  end
end

class MaintenanceSchedulesController < ApplicationController
  def index
    vehicle = Vehicle.find(params[:vehicle_id])
    authorize MaintenanceSchedule, :index?

    schedules = vehicle.maintenance_schedules
    schedules = schedules.where(is_active: cast_bool(params[:is_active])) unless params[:is_active].nil?
    schedules = schedules.where(priority: params[:priority]) if params[:priority].present?
    schedules = schedules.where(schedule_type: params[:schedule_type]) if params[:schedule_type].present?

    render json: { data: schedules.order(priority: :asc, next_due_at: :asc, next_due_km: :asc).map { |schedule| schedule_payload(schedule) } }
  end

  def create
    vehicle = Vehicle.find(params[:vehicle_id])
    authorize MaintenanceSchedule, :create?

    schedule = vehicle.maintenance_schedules.new(maintenance_schedule_params)
    schedule.creator = current_user if schedule.has_attribute?(:created_by)
    schedule.vehicle_type ||= vehicle.kind
    schedule.last_performed_at ||= Time.current
    schedule.last_performed_km ||= schedule.current_odometer_km
    schedule.next_due_km ||= schedule.mileage_interval_km.present? ? schedule.last_performed_km.to_i + schedule.mileage_interval_km.to_i : nil
    schedule.next_due_at ||= schedule.time_interval_days.present? ? schedule.last_performed_at + schedule.time_interval_days.days : nil

    schedule.save!
    render json: schedule_payload(schedule), status: :created
  end

  def update
    schedule = MaintenanceSchedule.find(params[:id])
    authorize schedule, :update?

    interval_changed = schedule.mileage_interval_km.to_i != maintenance_schedule_params[:mileage_interval_km].to_i ||
      schedule.time_interval_days.to_i != maintenance_schedule_params[:time_interval_days].to_i
    schedule.assign_attributes(maintenance_schedule_params)
    if interval_changed
      performed_at = schedule.last_performed_at || Time.current
      performed_km = schedule.last_performed_km || schedule.current_odometer_km
      schedule.next_due_km = schedule.mileage_interval_km.present? ? performed_km + schedule.mileage_interval_km : nil
      schedule.next_due_at = schedule.time_interval_days.present? ? performed_at + schedule.time_interval_days.days : nil
    end
    schedule.save!

    render json: schedule_payload(schedule)
  end

  def destroy
    schedule = MaintenanceSchedule.find(params[:id])
    authorize schedule, :destroy?

    schedule.update!(is_active: false)
    head :no_content
  end

  def due
    authorize MaintenanceSchedule, :due?

    schedules = MaintenanceSchedule.active.includes(:vehicle)
    schedules = schedules.where(priority: params[:priority]) if params[:priority].present?
    schedules = schedules.where(vehicle_id: params[:vehicle_id]) if params[:vehicle_id].present?

    payload = schedules.map { |schedule| schedule_payload(schedule) }
    payload.select! { |s| s[:is_overdue] || s[:is_approaching_due] }
    payload.select! { |s| s[:is_overdue] } if cast_bool(params[:overdue_only])
    payload.sort_by! { |entry| [entry[:is_overdue] ? 0 : 1, entry[:days_until_due] || 9_999, entry[:km_until_due] || 9_999_999] }

    render json: { data: payload }
  end

  def apply_template
    authorize MaintenanceSchedule, :apply_template?

    vehicle_id = params[:vehicle_id] || params.dig(:maintenance_schedule, :vehicle_id)
    template_name = params[:template] || params.dig(:maintenance_schedule, :template)

    raise ActionController::BadRequest, "vehicle_id is required" if vehicle_id.blank?

    vehicle = Vehicle.find(vehicle_id)

    if template_name.blank?
      custom = build_custom_schedule_from_template_request(vehicle)
      custom.save!
      render json: { created_count: 1, data: [schedule_payload(custom)] }, status: :created
      return
    end

    template = Maintenance::TemplateCatalog.fetch(template_name)
    raise ActionController::BadRequest, "Unknown template" if template.blank?

    created = []
    MaintenanceSchedule.transaction do
      current_odometer = [vehicle.trips.maximum(:end_odometer_km), vehicle.trips.maximum(:start_odometer_km)].compact.max.to_i
      template.each do |attrs|
        schedule = vehicle.maintenance_schedules.new(
          attrs.merge(
            vehicle_type: vehicle.kind,
            last_performed_at: Time.current,
            last_performed_km: current_odometer,
            next_due_km: attrs[:mileage_interval_km].present? ? (current_odometer + attrs[:mileage_interval_km].to_i) : nil,
            next_due_at: attrs[:time_interval_days].present? ? Time.current + attrs[:time_interval_days].days : nil,
            is_active: true
          )
        )
        schedule.creator = current_user if schedule.has_attribute?(:created_by)
        schedule.save!
        created << schedule
      end
    end

    render json: { template: template_name, created_count: created.size, data: created.map { |schedule| schedule_payload(schedule) } }, status: :created
  end

  def templates
    authorize MaintenanceSchedule, :apply_template?

    render json: {
      data: Maintenance::TemplateCatalog.keys.map do |name|
        rows = Maintenance::TemplateCatalog.fetch(name) || []
        {
          key: name,
          items_count: rows.size,
          items: rows
        }
      end
    }
  end

  private

  def maintenance_schedule_params
    params.require(:maintenance_schedule).permit(
      :name,
      :description,
      :schedule_type,
      :mileage_interval_km,
      :time_interval_days,
      :priority,
      :is_active,
      :notify_before_km,
      :notify_before_days,
      :estimated_duration_hrs,
      :estimated_cost,
      :last_performed_at,
      :last_performed_km,
      :vehicle_type
    )
  end

  def schedule_payload(schedule)
    {
      id: schedule.id,
      vehicle_id: schedule.vehicle_id,
      vehicle_type: schedule.vehicle_type,
      name: schedule.name,
      description: schedule.description,
      schedule_type: schedule.schedule_type,
      mileage_interval_km: schedule.mileage_interval_km,
      time_interval_days: schedule.time_interval_days,
      priority: schedule.priority,
      is_active: schedule.is_active,
      notify_before_km: schedule.notify_before_km,
      notify_before_days: schedule.notify_before_days,
      estimated_duration_hrs: schedule.estimated_duration_hrs,
      estimated_cost: schedule.estimated_cost,
      last_performed_at: schedule.last_performed_at,
      last_performed_km: schedule.last_performed_km,
      next_due_at: schedule.next_due_at,
      next_due_km: schedule.next_due_km,
      km_until_due: schedule.km_until_due,
      days_until_due: schedule.days_until_due,
      is_overdue: schedule.overdue?,
      is_approaching_due: schedule.approaching_due?
    }
  end

  def cast_bool(value)
    ActiveModel::Type::Boolean.new.cast(value)
  end

  def build_custom_schedule_from_template_request(vehicle)
    input = params[:maintenance_schedule].is_a?(ActionController::Parameters) ? params[:maintenance_schedule].to_unsafe_h : {}
    input = input.with_indifferent_access
    input[:name] ||= params[:name]
    input[:description] ||= params[:description]
    input[:priority] ||= params[:priority]
    input[:schedule_type] ||= params[:schedule_type]
    input[:mileage_interval_km] ||= params[:mileage_interval_km]
    input[:time_interval_days] ||= params[:time_interval_days] || params[:interval_days]
    input[:next_due_km] ||= params[:next_due_km]
    input[:next_due_at] ||= params[:next_due_at]

    raise ActionController::BadRequest, "template or name is required" if input[:name].blank?

    schedule_type = input[:schedule_type].presence || inferred_schedule_type(input)
    current_odometer = [vehicle.trips.maximum(:end_odometer_km), vehicle.trips.maximum(:start_odometer_km)].compact.max.to_i
    last_performed_at = Time.current

    schedule = vehicle.maintenance_schedules.new(
      name: input[:name],
      description: input[:description],
      schedule_type: schedule_type,
      mileage_interval_km: input[:mileage_interval_km],
      time_interval_days: input[:time_interval_days],
      priority: input[:priority].presence || "medium",
      notify_before_km: input[:notify_before_km].to_i,
      notify_before_days: input[:notify_before_days].to_i,
      vehicle_type: vehicle.kind,
      last_performed_at: last_performed_at,
      last_performed_km: current_odometer,
      next_due_km: input[:next_due_km].presence || (input[:mileage_interval_km].present? ? current_odometer + input[:mileage_interval_km].to_i : nil),
      next_due_at: input[:next_due_at].presence || (input[:time_interval_days].present? ? last_performed_at + input[:time_interval_days].to_i.days : nil),
      is_active: true
    )
    schedule.creator = current_user if schedule.has_attribute?(:created_by)
    schedule
  end

  def inferred_schedule_type(input)
    mileage_present = input[:mileage_interval_km].present?
    time_present = input[:time_interval_days].present? || input[:interval_days].present?
    return "both" if mileage_present && time_present
    return "mileage" if mileage_present

    "time"
  end
end

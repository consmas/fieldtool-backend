module Maintenance
  class CheckDueJob < ApplicationJob
    queue_as :low

    def perform
      MaintenanceSchedule.active.includes(:vehicle).find_each do |schedule|
        next unless schedule.vehicle_id.present?

        next unless schedule.approaching_due? || schedule.overdue?

        existing = WorkOrder.where(maintenance_schedule_id: schedule.id).where(status: %w[draft open in_progress on_hold]).exists?
        next if existing || !schedule.overdue?

        WorkOrder.create!(
          vehicle_id: schedule.vehicle_id,
          maintenance_schedule_id: schedule.id,
          title: "#{schedule.name} - #{schedule.vehicle&.license_plate}",
          description: schedule.description,
          work_order_type: "preventive",
          status: "draft",
          priority: schedule.priority,
          scheduled_date: Date.current,
          reported_at: Time.current
        )
      end
    end
  end
end

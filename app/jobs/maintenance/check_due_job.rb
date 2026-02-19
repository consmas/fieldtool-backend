module Maintenance
  class CheckDueJob < ApplicationJob
    queue_as :low

    def perform
      MaintenanceSchedule.active.includes(:vehicle).find_each do |schedule|
        next unless schedule.vehicle_id.present?

        next unless schedule.approaching_due? || schedule.overdue?

        NotificationService.notify(
          notification_type: (schedule.overdue? ? "maintenance.overdue" : "maintenance.due_soon"),
          recipients: ["admin", "supervisor"],
          notifiable: schedule,
          data: {
            maintenance_name: schedule.name,
            vehicle_reg: schedule.vehicle&.license_plate,
            km_remaining: schedule.km_until_due,
            days_remaining: schedule.days_until_due
          },
          group_key: "maintenance_schedule_#{schedule.id}"
        )

        existing = WorkOrder.where(maintenance_schedule_id: schedule.id).where(status: %w[draft open in_progress on_hold]).exists?
        next if existing || !schedule.overdue?

        work_order = WorkOrder.create!(
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

        NotificationService.notify(
          notification_type: "maintenance.work_order_created",
          recipients: ["admin", "supervisor"],
          notifiable: work_order,
          data: {
            wo_number: work_order.work_order_number,
            vehicle_reg: schedule.vehicle&.license_plate,
            title: work_order.title
          }
        )
      end
    end
  end
end

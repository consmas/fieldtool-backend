module WorkOrders
  class CompletionJob < ApplicationJob
    queue_as :critical

    def perform(work_order_id, actor_id = nil)
      work_order = WorkOrder.find_by(id: work_order_id)
      return if work_order.nil? || work_order.status != "completed"

      if work_order.maintenance_schedule.present?
        performed_at = work_order.completed_at || Time.current
        performed_km = work_order.vehicle.trips.maximum(:end_odometer_km).to_i
        work_order.maintenance_schedule.refresh_due_targets!(performed_at: performed_at, performed_km: performed_km)
      end

      return if work_order.expense_entry_id.present?

      actor = User.find_by(id: actor_id)
      expense = ExpenseEntry.create!(
        trip_id: nil,
        vehicle_id: work_order.vehicle_id,
        driver_id: nil,
        category: :repairs_maintenance,
        description: [work_order.title, work_order.resolution_notes].compact.join(" - "),
        quantity: 1,
        unit_cost: work_order.actual_cost.to_d,
        amount: work_order.actual_cost.to_d,
        currency: "GHS",
        status: :pending,
        expense_date: work_order.completed_at || Time.current,
        reference: work_order.work_order_number,
        is_auto_generated: true,
        auto_rule_key: "maintenance_work_order_v1",
        created_by: actor,
        metadata: {
          work_order_id: work_order.id,
          work_order_type: work_order.work_order_type,
          vendor_id: work_order.vendor_id
        }
      )

      work_order.update!(expense_entry_id: expense.id)
      NotificationService.notify(
        notification_type: "maintenance.work_order_completed",
        recipients: ["admin", "finance"],
        notifiable: work_order,
        data: {
          wo_number: work_order.work_order_number,
          vehicle_reg: work_order.vehicle&.license_plate,
          cost: work_order.actual_cost.to_d
        }
      )
    end
  end
end

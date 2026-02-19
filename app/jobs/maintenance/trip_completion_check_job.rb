module Maintenance
  class TripCompletionCheckJob < ApplicationJob
    queue_as :default

    def perform(trip_id)
      trip = Trip.find_by(id: trip_id)
      return if trip.nil? || trip.vehicle_id.blank?

      odometer = trip.end_odometer_km.to_i
      schedules = trip.vehicle.maintenance_schedules.active

      schedules.find_each do |schedule|
        next if schedule.next_due_km.blank?

        threshold = schedule.next_due_km - schedule.notify_before_km.to_i
        next if odometer < threshold

        exists = WorkOrder.where(maintenance_schedule_id: schedule.id).where(status: %w[draft open in_progress on_hold]).exists?
        next if exists || odometer < schedule.next_due_km

        WorkOrder.create!(
          vehicle_id: trip.vehicle_id,
          maintenance_schedule_id: schedule.id,
          title: "#{schedule.name} - #{trip.vehicle&.license_plate}",
          description: schedule.description,
          work_order_type: "preventive",
          priority: schedule.priority,
          status: "draft",
          odometer_at_creation: odometer,
          reported_by: trip.dispatcher_id,
          reported_at: Time.current,
          scheduled_date: Date.current
        )
      end
    end
  end
end

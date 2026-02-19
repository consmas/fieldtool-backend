module Maintenance
  class DriverController < ApplicationController
    def my_vehicle
      vehicle = current_vehicle_for_driver
      return render json: { data: nil, message: "No vehicle assigned" } if vehicle.nil?

      render json: {
        data: detailed_payload(vehicle)
      }
    end

    def snapshot
      vehicle = current_vehicle_for_driver
      return render json: { data: nil, message: "No vehicle assigned" } if vehicle.nil?

      schedules = vehicle.maintenance_schedules.active
      overdue = schedules.select(&:overdue?)
      due_soon = schedules.select(&:approaching_due?)
      open_orders = vehicle.work_orders.where(status: %w[draft open in_progress on_hold])
      docs = vehicle.vehicle_documents

      render json: {
        data: {
          vehicle_id: vehicle.id,
          next_due: schedule_payload(schedules.min_by { |s| [s.days_until_due || 9_999, s.km_until_due || 9_999_999] }),
          overdue_count: overdue.size,
          due_soon_count: due_soon.size,
          open_work_orders_count: open_orders.count,
          documents_expiring_count: docs.where(status: "expiring_soon").count,
          documents_expired_count: docs.where(status: "expired").count,
          updated_at: Time.current
        }
      }
    end

    def driver_maintenance
      vehicle = current_vehicle_for_driver
      return render json: { data: nil, message: "No vehicle assigned" } if vehicle.nil?

      render json: {
        data: detailed_payload(vehicle)
      }
    end

    private

    def current_vehicle_for_driver
      return nil unless current_user.driver?

      active_statuses = %w[assigned loaded en_route arrived offloaded]
      active_trip = current_user.assigned_trips.where(status: active_statuses).where.not(vehicle_id: nil).order(updated_at: :desc).first
      return active_trip.vehicle if active_trip&.vehicle

      latest_trip = current_user.assigned_trips.where.not(vehicle_id: nil).order(updated_at: :desc).first
      latest_trip&.vehicle
    end

    def detailed_payload(vehicle)
      schedules = vehicle.maintenance_schedules.active.order(next_due_at: :asc, next_due_km: :asc)
      open_orders = vehicle.work_orders.where(status: %w[draft open in_progress on_hold]).order(priority: :asc, scheduled_date: :asc)
      docs = vehicle.vehicle_documents.order(expires_at: :asc)

      {
        driver: {
          id: current_user.id,
          name: current_user.name,
          email: current_user.email
        },
        vehicle: {
          id: vehicle.id,
          name: vehicle.name,
          license_plate: vehicle.license_plate,
          kind: vehicle.kind
        },
        maintenance: {
          next_due: schedule_payload(schedules.first),
          schedules_due: schedules.select { |s| s.overdue? || s.approaching_due? }.map { |s| schedule_payload(s) },
          open_work_orders: open_orders.map do |wo|
            {
              id: wo.id,
              work_order_number: wo.work_order_number,
              title: wo.title,
              status: wo.status,
              priority: wo.priority,
              scheduled_date: wo.scheduled_date,
              assigned_to: wo.assigned_to
            }
          end,
          documents: docs.map do |doc|
            {
              id: doc.id,
              document_type: doc.document_type,
              status: doc.status,
              expires_at: doc.expires_at,
              days_until_expiry: doc.days_until_expiry
            }
          end
        }
      }
    end

    def schedule_payload(schedule)
      return nil if schedule.nil?

      {
        id: schedule.id,
        name: schedule.name,
        priority: schedule.priority,
        next_due_at: schedule.next_due_at,
        next_due_km: schedule.next_due_km,
        km_until_due: schedule.km_until_due,
        days_until_due: schedule.days_until_due,
        is_overdue: schedule.overdue?,
        is_approaching_due: schedule.approaching_due?
      }
    end
  end
end

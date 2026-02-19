module Webhooks
  module EventTypeRegistry
    EVENTS = {
      "trip.created" => "A new trip has been created",
      "trip.assigned" => "A trip has been assigned to a driver",
      "trip.started" => "A trip has transitioned to en_route",
      "trip.completed" => "A trip has been marked as completed",
      "trip.cancelled" => "A trip has been cancelled",
      "trip.status_changed" => "Any trip status transition",
      "inspection.submitted" => "A pre-trip inspection has been submitted",
      "inspection.verified" => "A pre-trip inspection has been verified by logistics",
      "inspection.failed" => "A pre-trip inspection has failed a checklist item",
      "trip.location_updated" => "New location ping received (batched)",
      "trip.eta_updated" => "ETA recalculated for an active trip",
      "trip.geofence_entered" => "Vehicle entered a geofence zone",
      "trip.geofence_exited" => "Vehicle exited a geofence zone",
      "delivery.completed" => "A delivery stop has been completed with POD",
      "delivery.failed" => "A delivery attempt failed",
      "expense.created" => "A new expense entry has been created",
      "expense.submitted" => "An expense has been submitted for approval",
      "expense.approved" => "An expense has been approved",
      "expense.rejected" => "An expense has been rejected",
      "expense.paid" => "An expense has been marked as paid",
      "vehicle.maintenance_due" => "A vehicle has hit a maintenance threshold",
      "driver.compliance_alert" => "A driver compliance issue has been flagged"
    }.freeze

    def self.supported?(event_type)
      EVENTS.key?(event_type.to_s)
    end
  end
end

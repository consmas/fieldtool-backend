module AuditActionRegistry
  ACTIONS = {
    "trip.created" => { category: "trip", severity: "info", description: "Trip created" },
    "trip.updated" => { category: "trip", severity: "info", description: "Trip details updated" },
    "trip.status_changed" => { category: "trip", severity: "info", description: "Trip status transitioned" },
    "trip.status_overridden" => { category: "trip", severity: "warning", description: "Trip status manually overridden" },
    "trip.assigned" => { category: "trip", severity: "info", description: "Trip assigned to driver" },
    "trip.reassigned" => { category: "trip", severity: "warning", description: "Trip reassigned" },
    "trip.cancelled" => { category: "trip", severity: "warning", description: "Trip cancelled" },
    "trip.deleted" => { category: "trip", severity: "critical", description: "Trip deleted" },
    "trip.completed" => { category: "trip", severity: "info", description: "Trip completed" },
    "trip.odometer_modified" => { category: "trip", severity: "warning", description: "Trip odometer modified" },

    "inspection.created" => { category: "inspection", severity: "info", description: "Inspection submitted" },
    "inspection.updated" => { category: "inspection", severity: "warning", description: "Inspection updated" },
    "inspection.failed" => { category: "inspection", severity: "critical", description: "Inspection failed" },
    "inspection.deleted" => { category: "inspection", severity: "critical", description: "Inspection deleted" },

    "expense.created" => { category: "expense", severity: "info", description: "Expense created" },
    "expense.updated" => { category: "expense", severity: "info", description: "Expense updated" },
    "expense.status_changed" => { category: "expense", severity: "info", description: "Expense status changed" },
    "expense.approved" => { category: "expense", severity: "info", description: "Expense approved" },
    "expense.rejected" => { category: "expense", severity: "info", description: "Expense rejected" },
    "expense.amount_modified" => { category: "expense", severity: "warning", description: "Expense amount modified" },
    "expense.deleted" => { category: "expense", severity: "critical", description: "Expense deleted" },

    "vehicle.created" => { category: "vehicle", severity: "info", description: "Vehicle created" },
    "vehicle.updated" => { category: "vehicle", severity: "info", description: "Vehicle updated" },
    "vehicle.deactivated" => { category: "vehicle", severity: "warning", description: "Vehicle deactivated" },
    "vehicle.document_uploaded" => { category: "vehicle", severity: "info", description: "Vehicle document uploaded" },
    "vehicle.document_expired" => { category: "vehicle", severity: "critical", description: "Vehicle document expired" },
    "vehicle.deleted" => { category: "vehicle", severity: "critical", description: "Vehicle deleted" },

    "driver.created" => { category: "driver", severity: "info", description: "Driver created" },
    "driver.updated" => { category: "driver", severity: "info", description: "Driver updated" },
    "driver.suspended" => { category: "driver", severity: "critical", description: "Driver suspended" },
    "driver.document_expired" => { category: "driver", severity: "critical", description: "Driver document expired" },
    "driver.score_calculated" => { category: "driver", severity: "info", description: "Driver score calculated" },

    "work_order.created" => { category: "maintenance", severity: "info", description: "Work order created" },
    "work_order.updated" => { category: "maintenance", severity: "info", description: "Work order updated" },
    "work_order.status_changed" => { category: "maintenance", severity: "info", description: "Work order status changed" },
    "work_order.completed" => { category: "maintenance", severity: "info", description: "Work order completed" },
    "work_order.deleted" => { category: "maintenance", severity: "critical", description: "Work order deleted" },

    "compliance.violation_created" => { category: "compliance", severity: "critical", description: "Compliance violation created" },
    "compliance.violation_resolved" => { category: "compliance", severity: "info", description: "Compliance violation resolved" },
    "compliance.waiver_granted" => { category: "compliance", severity: "security", description: "Compliance waiver granted" },
    "compliance.audit_completed" => { category: "compliance", severity: "info", description: "Compliance audit completed" },

    "incident.created" => { category: "incident", severity: "critical", description: "Incident reported" },
    "incident.updated" => { category: "incident", severity: "info", description: "Incident updated" },
    "incident.status_changed" => { category: "incident", severity: "info", description: "Incident status changed" },
    "incident.investigation_started" => { category: "incident", severity: "info", description: "Incident investigation started" },
    "incident.resolved" => { category: "incident", severity: "info", description: "Incident resolved" },
    "incident.insurance_claimed" => { category: "incident", severity: "info", description: "Incident insurance claim filed" },
    "incident.evidence_added" => { category: "incident", severity: "info", description: "Incident evidence added" },
    "incident.deleted" => { category: "incident", severity: "critical", description: "Incident deleted" },

    "fuel.logged" => { category: "fuel", severity: "info", description: "Fuel logged" },
    "fuel.anomaly_detected" => { category: "fuel", severity: "warning", description: "Fuel anomaly detected" },

    "invoice.created" => { category: "invoice", severity: "info", description: "Invoice created" },
    "invoice.sent" => { category: "invoice", severity: "info", description: "Invoice sent" },
    "invoice.voided" => { category: "invoice", severity: "warning", description: "Invoice voided" },

    "user.login" => { category: "user", severity: "info", description: "User logged in" },
    "user.logout" => { category: "user", severity: "info", description: "User logged out" },
    "user.login_failed" => { category: "user", severity: "security", description: "Failed login attempt" },
    "user.role_changed" => { category: "user", severity: "security", description: "User role changed" },

    "system.config_changed" => { category: "system", severity: "warning", description: "System config changed" },
    "system.data_exported" => { category: "system", severity: "security", description: "Data exported" },
    "system.bulk_operation" => { category: "system", severity: "warning", description: "Bulk operation" }
  }.freeze

  def self.fetch(action)
    ACTIONS[action.to_s]
  end
end

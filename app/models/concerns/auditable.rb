module Auditable
  extend ActiveSupport::Concern

  included do
    attr_accessor :audit_actor, :audit_request_context, :audit_metadata

    after_create :audit_creation
    after_update :audit_modification
    after_destroy :audit_deletion
  end

  private

  def audit_creation
    AuditService.record(
      action: "#{audit_action_prefix}.created",
      auditable: self,
      actor: audit_actor,
      request_context: audit_request_context,
      metadata: audit_metadata || {}
    )
  end

  def audit_modification
    return unless saved_changes.except("updated_at", "created_at").present?

    action = saved_changes.key?("status") ? "#{audit_action_prefix}.status_changed" : "#{audit_action_prefix}.updated"

    AuditService.record(
      action: action,
      auditable: self,
      actor: audit_actor,
      request_context: audit_request_context,
      metadata: audit_metadata || {}
    )
  end

  def audit_deletion
    AuditService.record(
      action: "#{audit_action_prefix}.deleted",
      auditable: self,
      actor: audit_actor,
      request_context: audit_request_context,
      severity: "critical",
      metadata: audit_metadata || {}
    )
  end

  def audit_action_prefix
    case self.class.name
    when "Trip" then "trip"
    when "ExpenseEntry" then "expense"
    when "Vehicle" then "vehicle"
    when "PreTripInspection" then "inspection"
    when "WorkOrder" then "work_order"
    when "Incident" then "incident"
    when "DriverProfile" then "driver"
    else self.class.name.underscore
    end
  end
end

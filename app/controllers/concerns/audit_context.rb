module AuditContext
  extend ActiveSupport::Concern

  included do
    before_action :set_audit_request_context
  end

  private

  def set_audit_request_context
    @audit_request_context = {
      ip: request.remote_ip,
      user_agent: request.user_agent,
      request_id: request.request_id,
      session_id: nil
    }
  end

  def set_audit_actor(record, metadata: nil)
    return record unless record.respond_to?(:audit_actor=)

    record.audit_actor = current_user
    record.audit_request_context = @audit_request_context
    record.audit_metadata = metadata if metadata.present?
    record
  end

  def audit(action:, auditable:, **opts)
    AuditService.record(
      action: action,
      auditable: auditable,
      actor: current_user,
      request_context: @audit_request_context,
      **opts
    )
  end
end

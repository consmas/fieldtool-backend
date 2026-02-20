class AuditLogPolicy < ApplicationPolicy
  def index?
    admin_or_dispatcher_or_supervisor_or_finance?
  end

  def summary?
    admin_or_dispatcher_or_supervisor_or_finance?
  end

  def export?
    user&.admin? || user&.supervisor? || user&.finance?
  end
end

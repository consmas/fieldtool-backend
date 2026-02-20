class ComplianceCheckPolicy < ApplicationPolicy
  def index?
    admin_or_dispatcher_or_supervisor? || user&.finance?
  end
end

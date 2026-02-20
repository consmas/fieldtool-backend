class ComplianceRequirementPolicy < ApplicationPolicy
  def index?
    admin_or_dispatcher_or_supervisor? || user&.finance?
  end

  def create?
    user&.admin? || user&.supervisor?
  end

  def update?
    user&.admin? || user&.supervisor?
  end
end

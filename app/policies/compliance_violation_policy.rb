class ComplianceViolationPolicy < ApplicationPolicy
  def index?
    admin_or_dispatcher_or_supervisor? || user&.finance?
  end

  def show?
    index?
  end

  def update?
    user&.admin? || user&.supervisor?
  end

  def waiver?
    user&.admin? || user&.supervisor?
  end

  def dashboard?
    index?
  end

  def reports?
    index?
  end
end

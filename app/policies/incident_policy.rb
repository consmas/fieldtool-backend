class IncidentPolicy < ApplicationPolicy
  def index?
    admin_or_dispatcher_or_supervisor? || user&.finance?
  end

  def show?
    return true if admin_or_dispatcher_or_supervisor? || user&.finance?

    user&.driver? && record.driver_id == user.id
  end

  def create?
    admin_or_dispatcher_or_supervisor? || user&.driver?
  end

  def update?
    admin_or_dispatcher_or_supervisor?
  end

  def dashboard?
    admin_or_dispatcher_or_supervisor? || user&.finance?
  end

  def reports?
    admin_or_dispatcher_or_supervisor? || user&.finance?
  end

  def my_incidents?
    user&.driver?
  end
end

class MaintenanceSchedulePolicy < ApplicationPolicy
  def index?
    admin_or_dispatcher_or_supervisor?
  end

  def show?
    admin_or_dispatcher_or_supervisor?
  end

  def create?
    admin_or_dispatcher_or_supervisor?
  end

  def update?
    admin_or_dispatcher_or_supervisor?
  end

  def destroy?
    admin_or_dispatcher_or_supervisor?
  end

  def due?
    admin_or_dispatcher_or_supervisor?
  end

  def apply_template?
    admin_or_dispatcher_or_supervisor?
  end
end

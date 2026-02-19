class WorkOrderPolicy < ApplicationPolicy
  def index?
    admin_or_dispatcher_or_supervisor_or_finance?
  end

  def show?
    admin_or_dispatcher_or_supervisor_or_finance?
  end

  def create?
    admin_or_dispatcher_or_supervisor?
  end

  def update?
    admin_or_dispatcher_or_supervisor?
  end

  def status?
    admin_or_dispatcher_or_supervisor?
  end

  def summary?
    admin_or_dispatcher_or_supervisor_or_finance?
  end

  def parts?
    admin_or_dispatcher_or_supervisor?
  end

  def comments?
    admin_or_dispatcher_or_supervisor_or_finance?
  end
end

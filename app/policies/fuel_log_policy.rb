class FuelLogPolicy < ApplicationPolicy
  def index?
    admin_or_dispatcher_or_supervisor_or_finance?
  end

  def create?
    admin_or_dispatcher_or_supervisor_or_finance? || user&.driver?
  end
end

class VehicleDocumentPolicy < ApplicationPolicy
  def index?
    admin_or_dispatcher_or_supervisor?
  end

  def create?
    admin_or_dispatcher_or_supervisor?
  end

  def update?
    admin_or_dispatcher_or_supervisor?
  end

  def expiring?
    admin_or_dispatcher_or_supervisor?
  end
end

class TripPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    admin_or_dispatcher_or_supervisor? || record.driver_id == user.id
  end

  def create?
    admin_or_dispatcher_or_supervisor?
  end

  def update?
    admin_or_dispatcher_or_supervisor? || record.driver_id == user.id
  end

  def change_status?
    admin_or_dispatcher_or_supervisor? || record.driver_id == user.id
  end

  def record_location?
    admin_or_dispatcher_or_supervisor? || record.driver_id == user.id
  end

  def add_evidence?
    admin_or_dispatcher_or_supervisor? || record.driver_id == user.id
  end

  def capture_odometer?
    admin_or_dispatcher_or_supervisor? || record.driver_id == user.id
  end

  class Scope < Scope
    def resolve
      return scope.all if user&.admin? || user&.dispatcher? || user&.supervisor?
      return scope.where(driver_id: user.id) if user&.driver?

      scope.none
    end
  end
end

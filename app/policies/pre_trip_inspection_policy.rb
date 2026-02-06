class PreTripInspectionPolicy < ApplicationPolicy
  def show?
    admin_or_dispatcher_or_supervisor? || record.trip.driver_id == user.id
  end

  def create?
    admin_or_dispatcher_or_supervisor? || record.trip.driver_id == user.id
  end

  def update?
    admin_or_dispatcher_or_supervisor? || record.trip.driver_id == user.id
  end
end

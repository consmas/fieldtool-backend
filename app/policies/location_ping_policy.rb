class LocationPingPolicy < ApplicationPolicy
  def create?
    return false unless user

    admin_or_dispatcher_or_supervisor? || record.trip.driver_id == user.id
  end

  def latest?
    return false unless user

    admin_or_dispatcher_or_supervisor? || record.trip.driver_id == user.id
  end
end

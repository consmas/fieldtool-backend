class TripStopPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    admin_or_dispatcher_or_supervisor? || record.trip.driver_id == user.id
  end

  def create?
    admin_or_dispatcher_or_supervisor? || record.trip.driver_id == user.id
  end

  def update?
    admin_or_dispatcher_or_supervisor? || record.trip.driver_id == user.id
  end

  def destroy?
    admin_or_dispatcher_or_supervisor?
  end

  class Scope < Scope
    def resolve
      return scope.all if user&.admin? || user&.dispatcher? || user&.supervisor?
      return scope.joins(:trip).where(trips: { driver_id: user.id }) if user&.driver?

      scope.none
    end
  end
end

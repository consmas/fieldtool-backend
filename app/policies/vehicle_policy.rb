class VehiclePolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present?
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

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end

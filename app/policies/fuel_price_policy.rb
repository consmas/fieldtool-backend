class FuelPricePolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def create?
    admin_or_dispatcher_or_supervisor?
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end

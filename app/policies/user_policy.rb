class UserPolicy < ApplicationPolicy
  def index?
    admin_or_dispatcher_or_supervisor?
  end

  def show?
    admin_or_dispatcher_or_supervisor? || record.id == user.id
  end

  def create?
    admin_or_dispatcher_or_supervisor?
  end

  def update?
    admin_or_dispatcher_or_supervisor? || record.id == user.id
  end

  class Scope < Scope
    def resolve
      return scope.all if user&.admin? || user&.dispatcher? || user&.supervisor?
      return scope.where(id: user.id) if user

      scope.none
    end
  end
end

class WebhookSubscriptionPolicy < ApplicationPolicy
  def index?
    allowed_role?
  end

  def show?
    allowed_role? && own_or_admin?
  end

  def create?
    allowed_role?
  end

  def update?
    allowed_role? && own_or_admin?
  end

  def destroy?
    allowed_role? && own_or_admin?
  end

  def test?
    update?
  end

  class Scope < Scope
    def resolve
      return scope.all if user&.admin?

      scope.where(user_id: user.id)
    end
  end

  private

  def allowed_role?
    user&.admin? || user&.dispatcher? || user&.supervisor?
  end

  def own_or_admin?
    user&.admin? || record.user_id == user.id
  end
end

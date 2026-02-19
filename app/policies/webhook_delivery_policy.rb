class WebhookDeliveryPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def retry?
    user&.admin?
  end

  class Scope < Scope
    def resolve
      return scope.all if user&.admin?

      scope.joins(:webhook_subscription).where(webhook_subscriptions: { user_id: user.id })
    end
  end
end

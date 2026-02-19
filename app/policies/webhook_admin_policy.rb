class WebhookAdminPolicy < ApplicationPolicy
  def show?
    finance_or_admin?
  end

  def stats?
    finance_or_admin?
  end

  def subscriptions?
    finance_or_admin?
  end

  def reactivate?
    finance_or_admin?
  end
end

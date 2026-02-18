class ExpenseEntryPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    return true if finance_or_admin? || user&.dispatcher? || user&.supervisor?
    return false unless user&.driver?

    record.driver_id == user.id || record.trip&.driver_id == user.id
  end

  def create?
    dispatcher_finance_or_admin?
  end

  def update?
    dispatcher_finance_or_admin?
  end

  def destroy?
    finance_or_admin?
  end

  def submit?
    dispatcher_finance_or_admin?
  end

  def approve?
    finance_or_admin?
  end

  def reject?
    finance_or_admin?
  end

  def mark_paid?
    finance_or_admin?
  end

  def bulk_workflow?
    finance_or_admin?
  end

  def summary?
    dispatcher_finance_or_admin? || user&.supervisor?
  end

  def run_automation?
    finance_or_admin?
  end

  class Scope < Scope
    def resolve
      return scope.active if user&.admin? || user&.finance? || user&.dispatcher? || user&.supervisor?
      return scope.active.where(driver_id: user.id) if user&.driver?

      scope.none
    end
  end

  private

  def dispatcher_finance_or_admin?
    user&.dispatcher? || user&.finance? || user&.admin?
  end
end

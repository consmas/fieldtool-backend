class FuelDepositPolicy < ApplicationPolicy
  def index?
    admin_or_dispatcher_or_supervisor_or_finance?
  end

  def show?
    admin_or_dispatcher_or_supervisor_or_finance?
  end

  def create?
    finance_or_admin?
  end

  def update?
    finance_or_admin?
  end

  def confirm?
    finance_or_admin?
  end

  def balances?
    admin_or_dispatcher_or_supervisor_or_finance?
  end

  def ledger?
    admin_or_dispatcher_or_supervisor_or_finance?
  end

  def reconcile?
    finance_or_admin?
  end

  class Scope < Scope
    def resolve
      return scope.all if user&.admin? || user&.finance? || user&.dispatcher? || user&.supervisor?

      scope.none
    end
  end
end

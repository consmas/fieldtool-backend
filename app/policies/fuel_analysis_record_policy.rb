class FuelAnalysisRecordPolicy < ApplicationPolicy
  def index?
    admin_or_dispatcher_or_supervisor_or_finance?
  end

  def anomalies?
    admin_or_dispatcher_or_supervisor_or_finance?
  end

  def investigate?
    finance_or_admin? || user&.supervisor?
  end

  def show?
    admin_or_dispatcher_or_supervisor_or_finance?
  end
end

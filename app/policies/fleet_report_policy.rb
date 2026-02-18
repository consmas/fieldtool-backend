class FleetReportPolicy < ApplicationPolicy
  def show?
    user&.admin? || user&.finance? || user&.dispatcher? || user&.supervisor?
  end
end

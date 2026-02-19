class DriverProfilePolicy < ApplicationPolicy
  def index?
    admin_or_dispatcher_or_supervisor_or_finance?
  end

  def show?
    admin_or_dispatcher_or_supervisor_or_finance? || record.user_id == user.id
  end

  def update?
    admin_or_dispatcher_or_supervisor?
  end

  def me?
    user&.driver?
  end

  def leaderboard?
    admin_or_dispatcher_or_supervisor_or_finance? || user&.driver?
  end

  def config?
    admin_or_dispatcher_or_supervisor_or_finance?
  end
end

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def update?
    false
  end

  def destroy?
    false
  end

  def admin_or_dispatcher_or_supervisor?
    user&.admin? || user&.dispatcher? || user&.supervisor?
  end

  def finance_or_admin?
    user&.finance? || user&.admin?
  end

  def admin_or_dispatcher_or_supervisor_or_finance?
    admin_or_dispatcher_or_supervisor? || user&.finance?
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.none
    end
  end
end

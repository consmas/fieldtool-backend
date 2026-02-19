class DriverDocumentPolicy < ApplicationPolicy
  def index?
    admin_or_dispatcher_or_supervisor_or_finance? || own_driver_doc?
  end

  def create?
    admin_or_dispatcher_or_supervisor? || own_driver_doc?
  end

  def update?
    admin_or_dispatcher_or_supervisor? || own_driver_doc?
  end

  def verify?
    admin_or_dispatcher_or_supervisor?
  end

  def compliance?
    admin_or_dispatcher_or_supervisor_or_finance?
  end

  private

  def own_driver_doc?
    return false unless user&.driver?
    profile_id = if record.is_a?(DriverProfile)
                   record.id
                 elsif record.is_a?(DriverDocument)
                   record.driver_profile_id
                 else
                   nil
                 end
    user.driver_profile&.id == profile_id
  end
end

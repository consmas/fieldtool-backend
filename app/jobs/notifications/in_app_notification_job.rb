module Notifications
  class InAppNotificationJob < ApplicationJob
    queue_as :default

    def perform(recipient_user_id:, kind:, payload: {})
      Rails.logger.info("[InAppNotification] recipient_user_id=#{recipient_user_id} kind=#{kind} payload=#{payload}")
    end
  end
end

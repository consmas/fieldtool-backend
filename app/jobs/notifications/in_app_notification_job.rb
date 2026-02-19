module Notifications
  class InAppNotificationJob < ApplicationJob
    queue_as :default

    def perform(notification_id)
      notification = Notification.find_by(id: notification_id)
      return if notification.nil?

      Rails.logger.info("[InAppNotification] notification_id=#{notification.id} recipient_id=#{notification.recipient_id} type=#{notification.notification_type}")
    end
  end
end

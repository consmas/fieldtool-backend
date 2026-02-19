module Notifications
  class DeliverEmailNotificationJob < ApplicationJob
    queue_as :mailers

    def perform(notification_id)
      notification = Notification.find_by(id: notification_id)
      return if notification.nil?

      Rails.logger.info("[EmailNotification] notification_id=#{notification.id} email=#{notification.recipient.email}")
    end
  end
end

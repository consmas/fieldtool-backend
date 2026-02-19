module Notifications
  class DeliverSmsNotificationJob < ApplicationJob
    queue_as :default

    def perform(notification_id)
      notification = Notification.find_by(id: notification_id)
      return if notification.nil?

      phone_number = notification.recipient.phone
      return if phone_number.blank?

      message = "#{notification.title}: #{notification.body}".truncate(160)
      Rails.logger.info("[SmsNotification] notification_id=#{notification.id} phone=#{phone_number} message=#{message}")
    end
  end
end

module Notifications
  class DeliverPushNotificationJob < ApplicationJob
    queue_as :default

    def perform(notification_id)
      notification = Notification.find_by(id: notification_id)
      return if notification.nil?

      tokens = notification.recipient.device_tokens.active
      tokens.find_each do |device_token|
        Rails.logger.info("[PushNotification] notification_id=#{notification.id} token_id=#{device_token.id} platform=#{device_token.platform}")
        device_token.update!(last_used_at: Time.current)
      end
    end
  end
end

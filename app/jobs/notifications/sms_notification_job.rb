module Notifications
  class SmsNotificationJob < ApplicationJob
    queue_as :default

    def perform(phone_number, message)
      user = User.find_by(phone: phone_number)
      return if user.nil?

      notification = Notification.create!(
        recipient_id: user.id,
        notification_type: "system.announcement",
        category: "system",
        title: "SMS Alert",
        body: message,
        priority: "normal",
        delivered_via: ["sms"]
      )
      DeliverSmsNotificationJob.perform_later(notification.id)
    end
  end
end

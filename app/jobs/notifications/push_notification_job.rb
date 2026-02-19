module Notifications
  class PushNotificationJob < ApplicationJob
    queue_as :default

    def perform(user_id, title, body, data = {})
      notification = Notification.create!(
        recipient_id: user_id,
        notification_type: data[:notification_type] || "system.announcement",
        category: "system",
        title: title,
        body: body,
        priority: "normal",
        data: data,
        delivered_via: ["push"]
      )
      DeliverPushNotificationJob.perform_later(notification.id)
    end
  end
end

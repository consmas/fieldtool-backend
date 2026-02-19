module Notifications
  class PushNotificationJob < ApplicationJob
    queue_as :default

    def perform(user_id, title, body, data = {})
      Rails.logger.info("[PushNotification] user_id=#{user_id} title=#{title} body=#{body} data=#{data}")
    end
  end
end

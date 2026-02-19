module Notifications
  class SmsNotificationJob < ApplicationJob
    queue_as :default

    def perform(phone_number, message)
      Rails.logger.info("[SmsNotification] phone=#{phone_number} message=#{message}")
    end
  end
end

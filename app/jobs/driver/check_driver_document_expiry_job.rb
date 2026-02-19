module Driver
  class CheckDriverDocumentExpiryJob < ApplicationJob
    queue_as :default

    def perform
      DriverDocument.where.not(expires_at: nil).find_each do |doc|
        next if doc.status == "renewed"

        days_remaining = (doc.expires_at - Date.current).to_i
        next_status = if days_remaining < 0
                        "expired"
                      elsif days_remaining <= doc.notify_before_days.to_i
                        "expiring_soon"
                      else
                        "active"
                      end

        next if doc.status == next_status

        doc.update!(status: next_status)
        notify(doc, days_remaining)
      end
    end

    private

    def notify(doc, days_remaining)
      profile = doc.driver_profile
      type = doc.status == "expired" ? "compliance.driver_document_expired" : "compliance.driver_document_expiring"
      NotificationService.notify(
        notification_type: type,
        recipients: ["supervisor", profile.user_id],
        notifiable: doc,
        data: {
          document_type: doc.document_type.humanize,
          driver_name: profile.user.name,
          days_remaining: days_remaining
        },
        priority: doc.status == "expired" ? "critical" : "high"
      )
    end
  end
end

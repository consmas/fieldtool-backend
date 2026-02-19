module Maintenance
  class CheckDocumentExpiryJob < ApplicationJob
    queue_as :low

    def perform
      VehicleDocument.where.not(expires_at: nil).find_each do |doc|
        next if doc.status == "renewed"

        days_remaining = (doc.expires_at - Date.current).to_i
        target_status = if days_remaining < 0
                          "expired"
                        elsif days_remaining <= doc.notify_before_days.to_i
                          "expiring_soon"
                        else
                          "active"
                        end

        next if doc.status == target_status

        doc.update!(status: target_status)
        NotificationService.notify(
          notification_type: (target_status == "expired" ? "compliance.document_expired" : "compliance.document_expiring"),
          recipients: ["admin", "supervisor"],
          notifiable: doc,
          data: {
            document_type: doc.document_type.to_s.humanize,
            vehicle_reg: doc.vehicle&.license_plate,
            days_remaining: days_remaining
          },
          group_key: "vehicle_document_#{doc.id}"
        )
      end
    end
  end
end

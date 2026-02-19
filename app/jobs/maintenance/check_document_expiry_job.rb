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

        doc.update!(status: target_status) if doc.status != target_status
      end
    end
  end
end

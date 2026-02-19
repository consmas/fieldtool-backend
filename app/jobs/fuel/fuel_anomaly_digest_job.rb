module Fuel
  class FuelAnomalyDigestJob < ApplicationJob
    queue_as :low

    def perform
      since = 1.day.ago
      new_anomalies = FuelAnalysisRecord.anomalies.where("created_at >= ?", since)
      pending = FuelAnalysisRecord.anomalies.where(investigation_status: ["pending", "investigating", nil])

      return if new_anomalies.count.zero? && pending.count.zero?

      NotificationService.notify(
        notification_type: "system.announcement",
        recipients: ["admin", "supervisor", "finance"],
        data: {
          title: "Fuel Anomaly Digest",
          message: "New anomalies: #{new_anomalies.count}, pending investigations: #{pending.count}"
        },
        priority: "high",
        group_key: "fuel_anomaly_digest"
      )
    end
  end
end

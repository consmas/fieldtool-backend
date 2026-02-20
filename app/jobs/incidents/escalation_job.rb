module Incidents
  class EscalationJob < ApplicationJob
    queue_as :default

    def perform
      Incident.where(status: "reported").where("created_at < ?", 2.hours.ago).find_each do |incident|
        NotificationService.notify(
          notification_type: "system.announcement",
          recipients: ["admin"],
          notifiable: incident,
          priority: "high",
          data: {
            title: "Incident escalation",
            message: "#{incident.incident_number} has not been acknowledged for over 2 hours"
          }
        )
      end

      Incident.where(status: "investigating").where("investigation_started_at < ?", 7.days.ago).find_each do |incident|
        NotificationService.notify(
          notification_type: "system.announcement",
          recipients: ["admin", "supervisor"],
          notifiable: incident,
          priority: "high",
          data: {
            title: "Investigation overdue",
            message: "#{incident.incident_number} has been investigating for more than 7 days"
          }
        )
      end
    end
  end
end

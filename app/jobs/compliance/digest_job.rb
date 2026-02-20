module Compliance
  class DigestJob < ApplicationJob
    queue_as :low

    def perform
      open_violations = ComplianceViolation.where(status: %w[open acknowledged remediation_in_progress escalated]).count
      critical_violations = ComplianceViolation.where(severity: "critical", status: %w[open acknowledged remediation_in_progress escalated]).count

      NotificationService.notify(
        notification_type: "system.announcement",
        recipients: ["admin", "supervisor"],
        data: {
          title: "Weekly Compliance Digest",
          message: "Open violations: #{open_violations}, critical: #{critical_violations}"
        },
        priority: critical_violations.positive? ? "high" : "normal"
      )
    end
  end
end

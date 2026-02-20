module Compliance
  class WaiverExpiryJob < ApplicationJob
    queue_as :low

    def perform
      ComplianceWaiver.where(status: "approved").where("effective_until < ?", Time.current).find_each do |waiver|
        waiver.update!(status: "expired")
        violation = waiver.compliance_violation
        next if violation.nil?

        violation.update!(status: "open") if violation.status == "waived"
        AuditService.record(action: "compliance.violation_created", auditable: violation, metadata: { source: "waiver_expiry", waiver_id: waiver.id })
      end
    end
  end
end

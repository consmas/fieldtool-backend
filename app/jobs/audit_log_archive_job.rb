class AuditLogArchiveJob < ApplicationJob
  queue_as :low

  def perform
    # Placeholder for partition/cold storage archival strategy.
    # We retain 24 months in primary DB and mark older rows for export.
    cutoff = 24.months.ago
    count = AuditLog.where("occurred_at < ?", cutoff).count
    Rails.logger.info("AUDIT_ARCHIVE_CANDIDATES=#{count} cutoff=#{cutoff}")
  end
end

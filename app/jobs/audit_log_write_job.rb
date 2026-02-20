class AuditLogWriteJob < ApplicationJob
  queue_as :critical

  def perform(attrs)
    AuditLog.create!(attrs.to_h.symbolize_keys)
  rescue StandardError => e
    Rails.logger.error("AUDIT LOG WRITE FAILED: #{e.message} data=#{attrs.to_json}")
  end
end

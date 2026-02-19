module Cleanup
  class ArchiveOldLocationPingsJob < ApplicationJob
    queue_as :low

    def perform(cutoff_days = 90)
      cutoff = cutoff_days.to_i.days.ago
      count = LocationPing.where("recorded_at < ?", cutoff).count
      Rails.logger.info("[Cleanup] archive_old_location_pings cutoff=#{cutoff.iso8601} count=#{count}")
    end
  end
end

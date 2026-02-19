module Driver
  class CalculateWeeklyDriverScoresJob < ApplicationJob
    queue_as :default

    def perform
      period = (Date.current - 7.days).strftime("%Y-W%V")
      DriverProfile.where(is_active: true, status: "active").find_each do |profile|
        DriverScoringService.calculate_score(profile, period_type: "weekly", period: period)
      rescue StandardError => e
        Rails.logger.error("[DriverScoreWeekly] profile_id=#{profile.id} error=#{e.class}: #{e.message}")
      end
    end
  end
end

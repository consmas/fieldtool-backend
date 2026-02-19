module Driver
  class CalculateMonthlyDriverScoresJob < ApplicationJob
    queue_as :default

    def perform
      period = (Date.current - 1.month).strftime("%Y-%m")
      DriverProfile.where(is_active: true, status: "active").find_each do |profile|
        DriverScoringService.calculate_score(profile, period_type: "monthly", period: period)
      rescue StandardError => e
        Rails.logger.error("[DriverScoreMonthly] profile_id=#{profile.id} error=#{e.class}: #{e.message}")
      end
    end
  end
end

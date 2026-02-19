module Driver
  class DriverScoreNotificationJob < ApplicationJob
    queue_as :default

    def perform
      period = (Date.current - 7.days).strftime("%Y-W%V")
      DriverScore.where(scoring_period: period, period_type: "weekly").includes(:driver_profile).find_each do |score|
        NotificationService.notify(
          notification_type: "driver.score_published",
          recipients: [score.driver_profile.user_id],
          notifiable: score,
          data: {
            overall_score: score.overall_score,
            tier: score.driver_profile.score_tier,
            badges_count: score.badges_earned.size,
            trend: score.trend
          }
        )
      end
    end
  end
end

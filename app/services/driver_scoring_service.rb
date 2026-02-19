class DriverScoringService
  class << self
    def calculate_score(driver_profile, period_type: "weekly", period: nil)
      period ||= current_period(period_type)
      trips = driver_trips_in_period(driver_profile, period, period_type)
      return nil if trips.empty?

      config = ScoringConfig.default!
      weights = config.normalized_weights

      safety = calculate_safety_score(trips)
      efficiency = calculate_efficiency_score(trips)
      compliance = calculate_compliance_score(driver_profile, trips)
      timeliness = calculate_timeliness_score(trips)
      professionalism = calculate_professionalism_score(trips)

      overall = (
        safety.to_d * weights[:safety].to_d +
        efficiency.to_d * weights[:efficiency].to_d +
        compliance.to_d * weights[:compliance].to_d +
        timeliness.to_d * weights[:timeliness].to_d +
        professionalism.to_d * weights[:professionalism].to_d
      ).round(1)

      previous = driver_profile.driver_scores.where(period_type: period_type).order(created_at: :desc).first
      trend = determine_trend(overall, previous&.overall_score)
      tier = score_to_tier(overall, config.normalized_tiers)
      badges = check_badges(driver_profile, safety, efficiency, compliance, timeliness, trips, period)

      record = DriverScore.create!(
        driver_profile_id: driver_profile.id,
        scoring_period: period,
        period_type: period_type,
        overall_score: overall,
        safety_score: safety,
        efficiency_score: efficiency,
        compliance_score: compliance,
        timeliness_score: timeliness,
        professionalism_score: professionalism,
        trips_in_period: trips.count,
        distance_in_period: trips.sum(:distance_km).to_d,
        incidents_in_period: count_incidents(trips),
        score_details: {
          safety: safety,
          efficiency: efficiency,
          compliance: compliance,
          timeliness: timeliness,
          professionalism: professionalism,
          weights: weights
        },
        trend: trend,
        badges_earned: badges.map(&:badge_type)
      )

      driver_profile.update!(current_score: overall, score_tier: tier)
      rank_drivers_for_period(period, period_type)

      NotificationService.notify(
        notification_type: "driver.score_published",
        recipients: [driver_profile.user_id],
        notifiable: record,
        data: { overall_score: overall, tier: tier, trend: trend, badges_count: badges.count }
      )

      if previous && score_to_tier(previous.overall_score, config.normalized_tiers) != tier
        NotificationService.notify(
          notification_type: "driver.tier_changed",
          recipients: [driver_profile.user_id],
          notifiable: record,
          data: {
            old_tier: score_to_tier(previous.overall_score, config.normalized_tiers),
            new_tier: tier,
            score: overall
          }
        )
      end

      record
    end

    def current_period(period_type)
      period_type == "weekly" ? Date.current.strftime("%Y-W%V") : Date.current.strftime("%Y-%m")
    end

    def driver_trips_in_period(profile, period, period_type)
      if period_type == "weekly"
        year, week = period.split("-W").map(&:to_i)
        start_date = Date.commercial(year, week, 1)
        end_date = start_date + 6.days
      else
        start_date = Date.parse("#{period}-01")
        end_date = start_date.end_of_month
      end

      Trip.where(driver_id: profile.user_id, status: :completed)
          .where(completed_at: start_date.beginning_of_day..end_date.end_of_day)
    end

    def calculate_safety_score(trips)
      score = 100.to_d
      score -= count_incidents(trips) * 15
      score -= trips.where.not(notes_incidents: [nil, ""]).count * 5
      score.clamp(0, 100)
    end

    def calculate_efficiency_score(trips)
      rows = FuelAnalysisRecord.where(trip_id: trips.select(:id))
      return 85.to_d if rows.empty?

      avg_variance = rows.average(:variance_percent).to_d
      score = 100.to_d
      score -= [avg_variance, 0].max * 1.5
      score += [-avg_variance, 0].max * 0.5
      score.clamp(0, 100)
    end

    def calculate_compliance_score(profile, trips)
      score = 100.to_d
      if trips.any?
        inspections_done = PreTripInspection.where(trip_id: trips.select(:id)).count
        inspection_rate = inspections_done.to_d / trips.count.to_d
        score -= (1 - inspection_rate) * 50
      end
      score -= profile.driver_documents.where(status: "expired").count * 10
      score.clamp(0, 100)
    end

    def calculate_timeliness_score(trips)
      completed = trips.where(status: :completed)
      return 85.to_d if completed.empty?

      late = completed.select do |trip|
        trip.respond_to?(:estimated_completion_at) && trip.try(:estimated_completion_at).present? && trip.completed_at.present? && trip.completed_at > trip.estimated_completion_at + 30.minutes
      end
      late_rate = late.count.to_d / completed.count.to_d
      score = 100.to_d - (late_rate * 40)
      score.clamp(0, 100)
    end

    def calculate_professionalism_score(trips)
      return 85.to_d unless defined?(Shipment)

      ratings = Shipment.where(trip_id: trips.select(:id)).where.not(client_rating: nil)
      return 85.to_d if ratings.empty?

      (ratings.average(:client_rating).to_d * 20).clamp(0, 100)
    end

    def score_to_tier(score, thresholds)
      value = score.to_d
      return "platinum" if value >= thresholds[:platinum].to_d
      return "gold" if value >= thresholds[:gold].to_d
      return "silver" if value >= thresholds[:silver].to_d
      return "bronze" if value >= thresholds[:bronze].to_d

      "probation"
    end

    def determine_trend(current, previous)
      return "stable" if previous.blank?

      diff = current.to_d - previous.to_d
      return "improving" if diff > 3
      return "declining" if diff < -3

      "stable"
    end

    def check_badges(profile, safety, efficiency, compliance, timeliness, trips, period)
      badges = []
      badges << create_badge(profile, "perfect_safety", "Safety Star", "Perfect safety score this period", period) if safety == 100 && trips.count >= 3
      badges << create_badge(profile, "fuel_champion", "Fuel Champion", "Top fuel efficiency this period", period) if efficiency >= 95
      badges << create_badge(profile, "compliance_king", "Compliance King", "Perfect compliance this period", period) if compliance == 100
      badges << create_badge(profile, "road_warrior", "Road Warrior", "Completed 10+ trips", period) if trips.count >= 10
      badges << create_badge(profile, "on_time_hero", "On-Time Hero", "All trips on time", period) if timeliness == 100 && trips.count >= 3
      badges.compact
    end

    def create_badge(profile, badge_type, title, description, period)
      DriverBadge.find_or_create_by!(driver_profile_id: profile.id, badge_type: badge_type, scoring_period: period) do |badge|
        badge.title = title
        badge.description = description
        badge.icon = badge_type
        badge.earned_at = Time.current
      end
    end

    def count_incidents(trips)
      trips.where.not(notes_incidents: [nil, ""]).count
    end

    def rank_drivers_for_period(period, period_type)
      DriverScore.where(scoring_period: period, period_type: period_type).order(overall_score: :desc).each_with_index do |score, index|
        score.update_column(:rank_in_fleet, index + 1)
      end
    end
  end
end

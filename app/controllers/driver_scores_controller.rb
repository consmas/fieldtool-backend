class DriverScoresController < ApplicationController
  def index
    profile = DriverProfile.find_by!(user_id: params[:driver_id])
    authorize profile, :show?, policy_class: DriverProfilePolicy

    scope = profile.driver_scores
    scope = scope.where(period_type: params[:period_type]) if params[:period_type].present?
    scope = scope.where("created_at >= ?", parse_time(params[:date_from])) if parse_time(params[:date_from]).present?
    scope = scope.where("created_at <= ?", parse_time(params[:date_to])) if parse_time(params[:date_to]).present?

    render json: { data: scope.order(created_at: :desc).map { |score| payload(score) } }
  end

  def current
    profile = DriverProfile.find_by!(user_id: params[:driver_id])
    authorize profile, :show?, policy_class: DriverProfilePolicy

    score = profile.driver_scores.order(created_at: :desc).first
    render json: score ? payload(score) : { data: nil }
  end

  def badges
    profile = DriverProfile.find_by!(user_id: params[:driver_id])
    authorize profile, :show?, policy_class: DriverProfilePolicy

    render json: {
      data: profile.driver_badges.order(earned_at: :desc).map do |badge|
        {
          id: badge.id,
          badge_type: badge.badge_type,
          title: badge.title,
          description: badge.description,
          icon: badge.icon,
          earned_at: badge.earned_at,
          scoring_period: badge.scoring_period
        }
      end
    }
  end

  private

  def payload(score)
    {
      id: score.id,
      scoring_period: score.scoring_period,
      period_type: score.period_type,
      overall_score: score.overall_score,
      safety_score: score.safety_score,
      efficiency_score: score.efficiency_score,
      compliance_score: score.compliance_score,
      timeliness_score: score.timeliness_score,
      professionalism_score: score.professionalism_score,
      trips_in_period: score.trips_in_period,
      distance_in_period: score.distance_in_period,
      incidents_in_period: score.incidents_in_period,
      score_details: score.score_details,
      rank_in_fleet: score.rank_in_fleet,
      trend: score.trend,
      badges_earned: score.badges_earned,
      created_at: score.created_at
    }
  end

  def parse_time(value)
    return nil if value.blank?

    Time.zone.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end

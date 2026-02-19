class DriversController < ApplicationController
  def index
    authorize DriverProfile

    scope = DriverProfile.includes(:user)
    User.where(role: :driver).find_each { |u| DriverProfile.find_or_create_by!(user_id: u.id) } if scope.empty?
    scope = DriverProfile.includes(:user)
    scope = scope.where(score_tier: params[:score_tier]) if params[:score_tier].present?
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(is_active: cast_bool(params[:is_active])) unless params[:is_active].nil?

    render json: scope.order(current_score: :desc).map { |profile| profile_payload(profile) }
  end

  def show
    profile = DriverProfile.find_or_create_by!(user_id: params[:id])
    profile = DriverProfile.includes(:user, :driver_scores, :driver_badges, :driver_documents).find(profile.id)
    authorize profile, :show?

    render json: profile_payload(profile).merge(
      score_history: profile.driver_scores.order(created_at: :desc).limit(12).map { |s| score_payload(s) },
      badges: profile.driver_badges.order(earned_at: :desc).map { |b| badge_payload(b) },
      document_summary: {
        total: profile.driver_documents.count,
        expired: profile.driver_documents.where(status: "expired").count,
        expiring_soon: profile.driver_documents.where(status: "expiring_soon").count
      },
      fuel_efficiency_average: FuelAnalysisRecord.where(driver_id: profile.user_id).average(:actual_km_per_liter).to_d.round(2)
    )
  end

  def update
    profile = DriverProfile.find_or_create_by!(user_id: params[:id])
    authorize profile, :update?

    profile.update!(driver_profile_params)
    render json: profile_payload(profile)
  end

  def leaderboard
    authorize DriverProfile, :leaderboard?

    period_type = params[:period_type].presence || "weekly"
    period = params[:period].presence || DriverScoringService.current_period(period_type)
    scores = DriverScore.includes(driver_profile: :user).where(period_type: period_type, scoring_period: period).order(overall_score: :desc)

    render json: scores.each_with_index.map do |score, index|
      {
        rank: score.rank_in_fleet || (index + 1),
        driver_id: score.driver_profile.user_id,
        name: score.driver_profile.user.name,
        score: score.overall_score,
        tier: score.driver_profile.score_tier,
        trend: score.trend,
        badges: score.badges_earned.size
      }
    end
  end

  private

  def driver_profile_params
    params.require(:driver_profile).permit(
      :employee_number,
      :license_number,
      :license_class,
      :license_issued_at,
      :license_expires_at,
      :license_issuing_authority,
      :date_of_birth,
      :date_hired,
      :emergency_contact_name,
      :emergency_contact_phone,
      :blood_type,
      :medical_fitness_expires_at,
      :years_experience,
      :current_score,
      :score_tier,
      :total_trips,
      :total_distance_km,
      :total_incidents,
      :is_active,
      :status,
      :notes,
      vehicle_types_qualified: [],
      metadata: {}
    )
  end

  def profile_payload(profile)
    {
      user_id: profile.user_id,
      name: profile.user.name,
      email: profile.user.email,
      phone_number: profile.user.phone_number,
      employee_number: profile.employee_number,
      license_number: profile.license_number,
      license_class: profile.license_class,
      current_score: profile.current_score,
      score_tier: profile.score_tier,
      total_trips: profile.total_trips,
      total_distance_km: profile.total_distance_km,
      total_incidents: profile.total_incidents,
      status: profile.status,
      is_active: profile.is_active
    }
  end

  def score_payload(score)
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
      rank_in_fleet: score.rank_in_fleet,
      trend: score.trend,
      badges_earned: score.badges_earned
    }
  end

  def badge_payload(badge)
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

  def cast_bool(value)
    ActiveModel::Type::Boolean.new.cast(value)
  end
end

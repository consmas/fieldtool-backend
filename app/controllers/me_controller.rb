class MeController < ApplicationController
  before_action :ensure_driver_profile_schema!, only: [:profile, :documents, :create_document, :scores, :badges, :rank, :improvement_tips]

  def profile
    render json: current_profile_payload
  end

  def documents
    profile = ensure_driver_profile!
    render json: {
      data: profile.driver_documents.order(expires_at: :asc).map do |doc|
        {
          id: doc.id,
          document_type: doc.document_type,
          title: doc.title,
          status: doc.status,
          verification_status: doc.verification_status,
          expires_at: doc.expires_at,
          days_until_expiry: doc.days_until_expiry,
          file_url: doc.file.attached? ? Rails.application.routes.url_helpers.rails_blob_url(doc.file, only_path: true) : nil
        }
      end
    }
  end

  def create_document
    profile = ensure_driver_profile!
    doc = profile.driver_documents.new(document_params)
    doc.file.attach(params[:file]) if params[:file].present?
    doc.verification_status = "unverified"
    doc.save!
    render json: { id: doc.id, document_type: doc.document_type, status: doc.status }, status: :created
  end

  def scores
    profile = ensure_driver_profile!
    render json: { data: profile.driver_scores.order(created_at: :desc).limit(24) }
  end

  def badges
    profile = ensure_driver_profile!
    render json: { data: profile.driver_badges.order(earned_at: :desc) }
  end

  def rank
    profile = ensure_driver_profile!
    score = profile.driver_scores.order(created_at: :desc).first
    if score
      total = DriverProfile.count
      render json: { rank: score.rank_in_fleet, out_of: total, score: score.overall_score, tier: profile.score_tier }
    else
      render json: { rank: nil, out_of: DriverProfile.count, score: nil, tier: profile.score_tier }
    end
  end

  def improvement_tips
    profile = ensure_driver_profile!
    score = profile.driver_scores.order(created_at: :desc).first
    return render json: { data: nil } if score.nil?

    dimensions = {
      safety: score.safety_score,
      efficiency: score.efficiency_score,
      compliance: score.compliance_score,
      timeliness: score.timeliness_score,
      professionalism: score.professionalism_score
    }
    lowest_dimension, lowest_score = dimensions.min_by { |_k, v| v.to_d }

    tips = case lowest_dimension
    when :efficiency
      [
        "Your fuel variance is above baseline.",
        "Reduce idling and maintain steady speed.",
        "Check tire pressure before each trip."
      ]
    when :safety
      [
        "Review pre-trip checks carefully.",
        "Report and avoid repeat incident patterns.",
        "Drive defensively in congested zones."
      ]
    when :compliance
      [
        "Complete all inspections before trip start.",
        "Renew expiring driver documents.",
        "Submit required records on time."
      ]
    when :timeliness
      [
        "Plan departure earlier for high-traffic routes.",
        "Use route checks before dispatch.",
        "Coordinate loading/offloading windows closely."
      ]
    else
      [
        "Maintain communication quality with dispatch.",
        "Keep delivery handoff records complete.",
        "Follow service etiquette at customer sites."
      ]
    end

    render json: {
      lowest_dimension: lowest_dimension,
      score: lowest_score,
      tips: tips,
      target_score: 80,
      actions: tips
    }
  end

  private

  def ensure_driver_profile_schema!
    required_tables = %w[driver_profiles driver_documents driver_scores driver_badges]
    missing = required_tables.reject { |table| ActiveRecord::Base.connection.data_source_exists?(table) }
    return if missing.empty?

    render json: { error: "Driver performance module is not migrated yet", missing_tables: missing }, status: :service_unavailable
  end

  def ensure_driver_profile!
    raise ActiveRecord::RecordNotFound, "Driver profile not found" unless current_user.driver?

    DriverProfile.find_or_create_by!(user_id: current_user.id)
  end

  def current_profile_payload
    profile = ensure_driver_profile!
    {
      user_id: profile.user_id,
      name: current_user.name,
      email: current_user.email,
      current_score: profile.current_score,
      score_tier: profile.score_tier,
      status: profile.status,
      total_trips: profile.total_trips,
      total_distance_km: profile.total_distance_km
    }
  end

  def document_params
    params.require(:document).permit(
      :document_type,
      :document_number,
      :title,
      :issued_at,
      :expires_at,
      :issuing_authority,
      :notify_before_days,
      :cost,
      :notes,
      metadata: {}
    )
  end
end

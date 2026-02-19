class Admin::ScoringConfigController < ApplicationController
  def show
    authorize :fleet_report, :show?

    cfg = ScoringConfig.default!
    render json: {
      weights: cfg.normalized_weights,
      tier_thresholds: cfg.normalized_tiers,
      badge_rules: cfg.badge_rules,
      metadata: cfg.metadata
    }
  end

  def update
    authorize :fleet_report, :show?

    cfg = ScoringConfig.default!
    weights = params[:weights]&.to_unsafe_h
    if weights.present?
      total = weights.values.map(&:to_d).sum
      return render json: { error: "weights must sum to 1.0" }, status: :unprocessable_entity unless (total - 1.0).abs <= 0.0001
      cfg.weights = weights
    end

    cfg.tier_thresholds = params[:tier_thresholds].to_unsafe_h if params[:tier_thresholds].present?
    cfg.badge_rules = params[:badge_rules].to_unsafe_h if params[:badge_rules].present?
    cfg.metadata = params[:metadata].to_unsafe_h if params[:metadata].present?
    cfg.save!

    render json: {
      weights: cfg.normalized_weights,
      tier_thresholds: cfg.normalized_tiers,
      badge_rules: cfg.badge_rules,
      metadata: cfg.metadata
    }
  end
end

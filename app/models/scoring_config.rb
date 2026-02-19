class ScoringConfig < ApplicationRecord
  DEFAULT_NAME = "default".freeze

  DEFAULT_WEIGHTS = {
    safety: 0.30,
    efficiency: 0.25,
    compliance: 0.20,
    timeliness: 0.15,
    professionalism: 0.10
  }.freeze

  DEFAULT_TIERS = {
    platinum: 90,
    gold: 80,
    silver: 70,
    bronze: 60,
    probation: 0
  }.freeze

  validates :name, presence: true, uniqueness: true

  def self.default!
    find_or_create_by!(name: DEFAULT_NAME) do |cfg|
      cfg.weights = DEFAULT_WEIGHTS
      cfg.tier_thresholds = DEFAULT_TIERS
      cfg.badge_rules = {}
    end
  end

  def normalized_weights
    (weights.presence || DEFAULT_WEIGHTS).with_indifferent_access
  end

  def normalized_tiers
    (tier_thresholds.presence || DEFAULT_TIERS).with_indifferent_access
  end
end

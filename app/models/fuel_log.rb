class FuelLog < ApplicationRecord
  TRANSACTION_TYPES = %w[allocation actual_fill fuel_card manual_entry].freeze
  FUEL_TYPES = %w[diesel petrol gas].freeze
  FUNDING_SOURCES = %w[cash fuel_card omc_deposit].freeze
  OMC_NAMES = %w[westport top_oil other].freeze

  belongs_to :vehicle
  belongs_to :trip, optional: true
  belongs_to :driver, class_name: "User", optional: true
  belongs_to :recorder, class_name: "User", foreign_key: :recorded_by, optional: true

  validates :transaction_type, inclusion: { in: TRANSACTION_TYPES }
  validates :fuel_type, inclusion: { in: FUEL_TYPES }
  validates :funding_source, inclusion: { in: FUNDING_SOURCES }
  validates :omc_name, inclusion: { in: OMC_NAMES }, allow_nil: true
  validates :liters, numericality: { greater_than: 0 }
  validates :cost_per_liter, numericality: { greater_than_or_equal_to: 0 }
  validates :fueled_at, presence: true
  validate :omc_required_for_omc_funding

  before_validation :compute_total_cost
  after_commit :trigger_fill_to_fill_analysis, on: [:create, :update]

  private

  def compute_total_cost
    self.total_cost = liters.to_d * cost_per_liter.to_d
  end

  def trigger_fill_to_fill_analysis
    return unless is_full_tank?

    FillToFillAnalysisService.analyze(self)
  rescue StandardError
    nil
  end

  def omc_required_for_omc_funding
    return unless funding_source == "omc_deposit"

    errors.add(:omc_name, "is required when funding_source is omc_deposit") if omc_name.blank?
  end
end

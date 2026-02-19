class FuelAnalysisRecord < ApplicationRecord
  ANALYSIS_TYPES = %w[per_trip fill_to_fill].freeze
  ANOMALY_TYPES = %w[overconsumption underconsumption impossible_reading].freeze
  SEVERITIES = %w[low medium high critical].freeze
  INVESTIGATION_STATUSES = %w[pending investigating explained confirmed_theft mechanical_issue dismissed].freeze

  belongs_to :vehicle
  belongs_to :trip, optional: true
  belongs_to :driver, class_name: "User", optional: true
  belongs_to :investigator, class_name: "User", foreign_key: :investigated_by, optional: true

  validates :analysis_type, inclusion: { in: ANALYSIS_TYPES }
  validates :anomaly_type, inclusion: { in: ANOMALY_TYPES }, allow_blank: true
  validates :anomaly_severity, inclusion: { in: SEVERITIES }, allow_blank: true
  validates :investigation_status, inclusion: { in: INVESTIGATION_STATUSES }, allow_blank: true

  scope :anomalies, -> { where(is_anomaly: true) }
end

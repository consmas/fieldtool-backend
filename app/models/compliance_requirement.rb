class ComplianceRequirement < ApplicationRecord
  CATEGORIES = %w[vehicle_documentation driver_certification load_compliance safety_equipment environmental operational financial].freeze
  APPLIES_TO = %w[vehicle driver trip organization].freeze
  ENFORCEMENT_LEVELS = %w[mandatory recommended optional].freeze
  CHECK_TYPES = %w[document_expiry periodic_inspection per_trip_check threshold manual].freeze
  CHECK_FREQUENCIES = %w[per_trip daily weekly monthly quarterly annually on_event].freeze

  has_many :compliance_checks, dependent: :destroy
  has_many :compliance_violations, dependent: :destroy

  validates :name, :code, :category, :applies_to, :enforcement_level, :check_type, presence: true
  validates :code, uniqueness: true
  validates :category, inclusion: { in: CATEGORIES }
  validates :applies_to, inclusion: { in: APPLIES_TO }
  validates :enforcement_level, inclusion: { in: ENFORCEMENT_LEVELS }
  validates :check_type, inclusion: { in: CHECK_TYPES }
  validates :check_frequency, inclusion: { in: CHECK_FREQUENCIES }, allow_blank: true

  scope :active, -> { where(is_active: true) }
end

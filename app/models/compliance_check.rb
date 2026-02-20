class ComplianceCheck < ApplicationRecord
  RESULTS = %w[compliant non_compliant warning waived not_applicable pending].freeze

  belongs_to :compliance_requirement
  belongs_to :checkable, polymorphic: true
  belongs_to :trip, optional: true

  has_one :compliance_violation, dependent: :destroy

  validates :result, inclusion: { in: RESULTS }
  validates :checked_at, presence: true
end

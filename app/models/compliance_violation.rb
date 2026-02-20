class ComplianceViolation < ApplicationRecord
  SEVERITIES = %w[low medium high critical].freeze
  STATUSES = %w[open acknowledged remediation_in_progress resolved waived escalated].freeze

  belongs_to :compliance_requirement
  belongs_to :compliance_check
  belongs_to :violatable, polymorphic: true
  belongs_to :trip, optional: true
  belongs_to :resolver, class_name: "User", foreign_key: :resolved_by, optional: true
  belongs_to :waiver_approver, class_name: "User", foreign_key: :waiver_approved_by, optional: true
  belongs_to :linked_incident, class_name: "Incident", optional: true

  has_one :compliance_waiver, dependent: :destroy

  validates :violation_number, presence: true, uniqueness: true
  validates :severity, inclusion: { in: SEVERITIES }
  validates :status, inclusion: { in: STATUSES }

  before_validation :assign_violation_number, on: :create

  scope :open_items, -> { where(status: %w[open acknowledged remediation_in_progress escalated]) }

  private

  def assign_violation_number
    return if violation_number.present?

    year = Time.current.year
    sequence = (self.class.where("violation_number LIKE ?", "VIO-#{year}-%").count + 1).to_s.rjust(4, "0")
    self.violation_number = "VIO-#{year}-#{sequence}"
  end
end

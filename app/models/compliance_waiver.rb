class ComplianceWaiver < ApplicationRecord
  STATUSES = %w[pending approved denied expired revoked].freeze

  belongs_to :compliance_violation
  belongs_to :approver, class_name: "User", foreign_key: :approved_by, optional: true

  validates :waiver_number, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :reason, presence: true

  before_validation :assign_waiver_number, on: :create

  private

  def assign_waiver_number
    return if waiver_number.present?

    year = Time.current.year
    sequence = (self.class.where("waiver_number LIKE ?", "WVR-#{year}-%").count + 1).to_s.rjust(4, "0")
    self.waiver_number = "WVR-#{year}-#{sequence}"
  end
end

class InsuranceClaim < ApplicationRecord
  CLAIM_TYPES = %w[vehicle_damage cargo_damage liability comprehensive third_party].freeze
  STATUSES = %w[draft filed under_review approved partially_approved denied settled withdrawn].freeze

  belongs_to :incident
  belongs_to :filer, class_name: "User", foreign_key: :filed_by, optional: true

  has_many_attached :documents

  validates :claim_number, presence: true, uniqueness: true
  validates :claim_type, inclusion: { in: CLAIM_TYPES }
  validates :status, inclusion: { in: STATUSES }

  before_validation :assign_claim_number, on: :create

  private

  def assign_claim_number
    return if claim_number.present?

    year = Time.current.year
    sequence = (self.class.where("claim_number LIKE ?", "CLM-#{year}-%").count + 1).to_s.rjust(5, "0")
    self.claim_number = "CLM-#{year}-#{sequence}"
  end
end

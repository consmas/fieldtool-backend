class DriverDocument < ApplicationRecord
  DOCUMENT_TYPES = %w[
    driving_license
    medical_fitness_certificate
    defensive_driving_certificate
    hazmat_certification
    first_aid_certificate
    fire_safety_certificate
    national_id
    passport
    employment_contract
    background_check
    drug_test_result
    training_completion
    insurance_coverage
    other
  ].freeze
  STATUSES = %w[active expiring_soon expired renewed revoked].freeze
  VERIFICATION_STATUSES = %w[unverified verified rejected].freeze

  belongs_to :driver_profile
  belongs_to :verifier, class_name: "User", foreign_key: :verified_by, optional: true

  has_one_attached :file

  validates :document_type, inclusion: { in: DOCUMENT_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :verification_status, inclusion: { in: VERIFICATION_STATUSES }

  before_validation :derive_status

  def days_until_expiry
    return nil if expires_at.blank?

    (expires_at - Date.current).to_i
  end

  private

  def derive_status
    return if expires_at.blank? || status == "renewed"

    self.status = if expires_at < Date.current
                    "expired"
                  elsif (expires_at - Date.current).to_i <= notify_before_days.to_i
                    "expiring_soon"
                  else
                    "active"
                  end
  end
end

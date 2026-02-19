class VehicleDocument < ApplicationRecord
  DOCUMENT_TYPES = %w[insurance registration road_worthiness emission_test permit other].freeze
  STATUSES = %w[active expiring_soon expired renewed].freeze

  belongs_to :vehicle
  has_one_attached :file

  validates :document_type, inclusion: { in: DOCUMENT_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :notify_before_days, numericality: { greater_than_or_equal_to: 0 }

  scope :expiring_within, ->(days) { where.not(expires_at: nil).where(expires_at: Date.current..(Date.current + days.to_i.days)) }

  before_validation :set_status_by_expiry

  def days_until_expiry
    return nil if expires_at.blank?

    (expires_at - Date.current).to_i
  end

  private

  def set_status_by_expiry
    return if expires_at.blank?
    return if status == "renewed"

    self.status = if expires_at < Date.current
                    "expired"
                  elsif (expires_at - Date.current).to_i <= notify_before_days.to_i
                    "expiring_soon"
                  else
                    "active"
                  end
  end
end

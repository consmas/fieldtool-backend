class PreTripInspection < ApplicationRecord
  enum :load_status, { full: 0, partial: 1 }
  enum :inspection_verification_status, { pending: 0, approved: 1, rejected: 2 }, prefix: true

  belongs_to :trip
  belongs_to :captured_by, class_name: "User"
  belongs_to :inspection_verified_by, class_name: "User", optional: true
  belongs_to :inspection_confirmed_by, class_name: "User", optional: true

  has_one_attached :odometer_photo
  has_one_attached :load_photo
  has_one_attached :waybill_photo
  has_one_attached :inspector_signature
  has_one_attached :inspector_photo

  validates :odometer_value_km, presence: true
  validates :odometer_captured_at, presence: true
  validates :brakes, :tyres, :lights, :mirrors, :horn, :fuel_sufficient, inclusion: { in: [true, false] }
  validates :accepted, inclusion: { in: [true, false] }
  validates :trip_id, uniqueness: true

  validate :odometer_photo_attached
  validate :accepted_at_required_when_accepted
  validate :load_fields_consistency

  private

  def odometer_photo_attached
    errors.add(:odometer_photo, "must be attached") unless odometer_photo.attached?
  end

  def accepted_at_required_when_accepted
    return unless accepted && accepted_at.blank?

    errors.add(:accepted_at, "must be present when accepted")
  end

  def load_fields_consistency
    return if load_area_ready.nil? && load_status.nil? && load_secured.nil? && load_note.blank? && !load_photo.attached?

    errors.add(:load_area_ready, "must be set") if load_area_ready.nil?
    errors.add(:load_status, "must be set") if load_status.nil?
    errors.add(:load_secured, "must be set") if load_secured.nil?
  end
end

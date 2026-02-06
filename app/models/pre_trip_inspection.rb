class PreTripInspection < ApplicationRecord
  enum :load_status, { full: 0, partial: 1 }

  belongs_to :trip
  belongs_to :captured_by, class_name: "User"

  has_one_attached :odometer_photo
  has_one_attached :load_photo
  has_one_attached :waybill_photo

  validates :odometer_value_km, presence: true
  validates :odometer_captured_at, presence: true
  validates :brakes, :tyres, :lights, :mirrors, :horn, :fuel_sufficient, :load_area_ready, inclusion: { in: [true, false] }
  validates :load_status, presence: true
  validates :load_secured, inclusion: { in: [true, false] }
  validates :accepted, inclusion: { in: [true, false] }
  validates :trip_id, uniqueness: true

  validate :odometer_photo_attached
  validate :accepted_at_required_when_accepted

  private

  def odometer_photo_attached
    errors.add(:odometer_photo, "must be attached") unless odometer_photo.attached?
  end

  def accepted_at_required_when_accepted
    return unless accepted && accepted_at.blank?

    errors.add(:accepted_at, "must be present when accepted")
  end
end

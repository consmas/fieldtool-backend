class Evidence < ApplicationRecord
  self.table_name = "evidence"
  enum :kind, {
    before_loading: 0,
    after_loading: 1,
    en_route: 2,
    arrival: 3,
    offloading: 4
  }

  belongs_to :trip
  belongs_to :uploaded_by, class_name: "User", inverse_of: :uploaded_evidence

  has_one_attached :photo

  validates :kind, presence: true
  validates :recorded_at, presence: true

  validate :photo_attached
  validate :trip_not_completed

  private

  def trip_not_completed
    return unless trip&.status_completed?

    errors.add(:base, "Evidence is read-only once a trip is completed")
  end

  def photo_attached
    errors.add(:photo, "must be attached") unless photo.attached?
  end
end

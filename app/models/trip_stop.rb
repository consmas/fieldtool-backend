class TripStop < ApplicationRecord
  enum :pod_type, {
    photo: 0,
    e_signature: 1,
    manual: 2
  }, prefix: true

  belongs_to :trip

  validates :sequence, presence: true
  validates :sequence, numericality: { only_integer: true, greater_than: 0 }
  validates :trip_id, uniqueness: { scope: :sequence }
end

class LocationPing < ApplicationRecord
  belongs_to :trip
  belongs_to :recorded_by, class_name: "User", optional: true, inverse_of: :recorded_location_pings

  validates :lat, :lng, :recorded_at, presence: true
end

class TripEvent < ApplicationRecord
  belongs_to :trip
  belongs_to :created_by, class_name: "User", optional: true, inverse_of: :created_trip_events

  validates :event_type, presence: true
end

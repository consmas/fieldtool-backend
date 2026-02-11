class Destination < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :average_distance_km, :base_km, :base_trip_cost, :liters_per_km, presence: true
  validates :base_km, :liters_per_km, numericality: { greater_than: 0 }
end

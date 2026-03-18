class Destination < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :average_distance_km, :base_km, :base_trip_cost, :kms_per_liter, :additional_provision_pct, presence: true
  validates :base_km, :kms_per_liter, numericality: { greater_than: 0 }
  validates :additional_provision_pct, numericality: { greater_than_or_equal_to: 0, less_than: 1 }
end

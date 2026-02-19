module Fuel
  class FuelBaselineRecalculationJob < ApplicationJob
    queue_as :low

    def perform
      Vehicle.find_each do |vehicle|
        records = vehicle.fuel_analysis_records.where(analysis_type: "per_trip").order(created_at: :desc).limit(100)
        next if records.empty?

        total_distance = records.sum { |r| r.distance_km.to_d }
        total_fuel = records.sum { |r| r.fuel_consumed_liters.to_d }
        next if total_fuel <= 0

        baseline = (total_distance / total_fuel).round(2)
        vehicle.update!(baseline_km_per_liter: baseline)
      end
    end
  end
end

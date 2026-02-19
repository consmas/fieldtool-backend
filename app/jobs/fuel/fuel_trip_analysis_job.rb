module Fuel
  class FuelTripAnalysisJob < ApplicationJob
    queue_as :default

    def perform(trip_id)
      trip = Trip.find_by(id: trip_id)
      return if trip.nil?

      FuelAnalysisService.analyze_trip(trip)
    end
  end
end

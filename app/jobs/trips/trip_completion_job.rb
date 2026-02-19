module Trips
  class TripCompletionJob < ApplicationJob
    queue_as :default

    def perform(trip_id, actor_id = nil)
      trip = Trip.find_by(id: trip_id)
      return if trip.nil?

      actor = User.find_by(id: actor_id) if actor_id.present?
      Expenses::RecalculateFuelExpenseJob.perform_later(trip_ids: [trip.id], actor_id: actor&.id)
      Maintenance::TripCompletionCheckJob.perform_later(trip.id)
    end
  end
end

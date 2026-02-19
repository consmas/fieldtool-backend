module Expenses
  class AutoGenerateRoadExpenseJob < ApplicationJob
    queue_as :critical

    retry_on StandardError, wait: :exponentially_longer, attempts: 5

    def perform(trip_id, actor_id = nil)
      trip = Trip.find_by(id: trip_id)
      return if trip.nil?

      actor = User.find_by(id: actor_id) if actor_id.present?
      Expenses::RoadFeeAutoGenerator.call!(trip: trip, actor: actor)
    end
  end
end

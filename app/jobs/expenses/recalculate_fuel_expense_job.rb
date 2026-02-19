module Expenses
  class RecalculateFuelExpenseJob < ApplicationJob
    queue_as :default

    retry_on StandardError, wait: :exponentially_longer, attempts: 5

    def perform(trip_ids: nil, actor_id: nil, price_per_liter_override: nil)
      scope = Trip.all
      ids = Array(trip_ids).map(&:to_i).uniq
      scope = scope.where(id: ids) if ids.any?

      actor = User.find_by(id: actor_id)
      Expenses::FuelRecalculator.call(scope: scope, actor: actor, price_per_liter_override: price_per_liter_override)
    end
  end
end

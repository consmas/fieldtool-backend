module Expenses
  class RecalculateFuelExpenseJob < ApplicationJob
    queue_as :default

    retry_on StandardError, wait: :exponentially_longer, attempts: 5

    def perform(trip_ids: nil, actor_id: nil, price_per_liter_override: nil, date_from: nil, date_to: nil, target_statuses: nil)
      scope = Trip.all
      ids = Array(trip_ids).map(&:to_i).uniq
      scope = scope.where(id: ids) if ids.any?
      from = parse_time(date_from)
      to = parse_time(date_to)
      scope = scope.where("trip_date >= ?", from.to_date) if from.present?
      scope = scope.where("trip_date <= ?", to.to_date) if to.present?

      actor = User.find_by(id: actor_id)
      Expenses::FuelRecalculator.call(
        scope: scope,
        actor: actor,
        price_per_liter_override: price_per_liter_override,
        target_statuses: target_statuses
      )
    end

    private

    def parse_time(value)
      return nil if value.blank?

      Time.zone.parse(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end
  end
end

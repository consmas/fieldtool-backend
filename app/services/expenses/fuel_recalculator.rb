module Expenses
  class FuelRecalculator
    RULE_KEY = "fuel_mapping_v1".freeze
    DEFAULT_TARGET_STATUSES = %w[pending approved].freeze

    Result = Struct.new(:processed, :updated, :created, :skipped, :errors, keyword_init: true)

    def self.call(scope:, actor:, price_per_liter_override: nil, target_statuses: DEFAULT_TARGET_STATUSES)
      result = Result.new(processed: 0, updated: 0, created: 0, skipped: 0, errors: [])
      statuses = Array(target_statuses).map(&:to_s).presence || DEFAULT_TARGET_STATUSES

      scope.find_each do |trip|
        result.processed += 1
        liters = trip.fuel_litres_filled.presence || trip.fuel_allocated_litres.presence
        if liters.blank?
          result.skipped += 1
          next
        end

        price, source = resolve_price(price_per_liter_override, trip)
        if price.blank?
          result.skipped += 1
          next
        end

        amount = liters.to_d * price.to_d
        expense = ExpenseEntry.active.find_or_initialize_by(trip_id: trip.id, category: :fuel, auto_rule_key: RULE_KEY)
        if expense.persisted? && !statuses.include?(expense.status)
          result.skipped += 1
          next
        end

        previous_amount = expense.amount.to_d
        expense.assign_attributes(
          vehicle: trip.vehicle,
          driver: trip.driver,
          amount: amount.round(2),
          expense_date: trip.trip_date || expense.expense_date || Time.current.to_date,
          currency: "GHS",
          status: expense.status.presence || :pending,
          description: "Fuel expense mapped from trip fuel usage",
          is_auto_generated: true,
          created_by: expense.created_by || actor,
          metadata: {
            liters_used: liters.to_d,
            price_per_liter: price.to_d,
            price_source: source,
            computed_at: Time.current
          }
        )
        was_new = expense.new_record?
        old_status = expense.status
        expense.save!

        Expenses::AuditLogger.log!(
          expense_entry: expense,
          actor: actor,
          action: was_new ? "fuel_recalculation_created" : "fuel_recalculation_updated",
          from_status: was_new ? nil : old_status,
          to_status: expense.status,
          metadata: expense.metadata.merge(
            previous_amount: previous_amount,
            recalculated_amount: expense.amount.to_d
          )
        )

        was_new ? result.created += 1 : result.updated += 1
      rescue StandardError => e
        result.errors << { trip_id: trip.id, error: e.message }
      end

      result
    end

    def self.resolve_price(price_override, trip)
      return [price_override.to_d, "manual_override"] if price_override.present?

      base_time = trip.trip_date.present? ? trip.trip_date.to_time.in_time_zone.end_of_day : Time.current
      price = FuelPrice.where("effective_at <= ?", base_time).order(effective_at: :desc).first
      price ||= FuelPrice.order(effective_at: :desc).first
      return [nil, nil] if price.nil?

      [price.price_per_liter.to_d, "effective_fuel_price"]
    end
  end
end

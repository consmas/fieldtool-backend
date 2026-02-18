module Expenses
  class FuelRecalculator
    RULE_KEY = "fuel_mapping_v1".freeze

    Result = Struct.new(:processed, :updated, :created, :skipped, :errors, keyword_init: true)

    def self.call(scope:, actor:, price_per_liter_override: nil)
      result = Result.new(processed: 0, updated: 0, created: 0, skipped: 0, errors: [])

      scope.find_each do |trip|
        result.processed += 1
        liters = trip.fuel_litres_filled.presence || trip.fuel_allocated_litres.presence
        if liters.blank?
          result.skipped += 1
          next
        end

        price, source = resolve_price(price_per_liter_override)
        if price.blank?
          result.skipped += 1
          next
        end

        amount = liters.to_d * price.to_d
        expense = ExpenseEntry.active.find_or_initialize_by(trip_id: trip.id, category: :fuel, auto_rule_key: RULE_KEY)
        if expense.persisted? && expense.status == "paid"
          result.skipped += 1
          next
        end

        expense.assign_attributes(
          vehicle: trip.vehicle,
          driver: trip.driver,
          amount: amount.round(2),
          expense_date: Time.current,
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
          metadata: expense.metadata
        )

        was_new ? result.created += 1 : result.updated += 1
      rescue StandardError => e
        result.errors << { trip_id: trip.id, error: e.message }
      end

      result
    end

    def self.resolve_price(price_override)
      return [price_override.to_d, "manual_override"] if price_override.present?

      latest = FuelPrice.order(effective_at: :desc).first
      return [nil, nil] if latest.nil?

      [latest.price_per_liter.to_d, "latest_fuel_price"]
    end
  end
end

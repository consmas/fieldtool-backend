module Expenses
  class RoadFeeAutoGenerator
    ROAD_FEE_RULE_KEY = "road_fee_en_route_v1".freeze
    DEFAULT_AMOUNT = BigDecimal("100")

    def self.call!(trip:, actor: nil)
      return nil if trip.nil?
      return nil unless trip.status == "en_route"

      existing = ExpenseEntry.active.where(trip_id: trip.id, category: :road_expenses).first
      return existing if existing.present?

      expense = ExpenseEntry.create!(
        trip: trip,
        vehicle: trip.vehicle,
        driver: trip.driver,
        category: :road_expenses,
        amount: DEFAULT_AMOUNT,
        currency: "GHS",
        status: :pending,
        expense_date: Time.current,
        description: "Auto road fee created when trip entered en_route",
        is_auto_generated: true,
        auto_rule_key: ROAD_FEE_RULE_KEY,
        created_by: actor
      )

      Expenses::AuditLogger.log!(
        expense_entry: expense,
        actor: actor,
        action: "auto_road_fee_created",
        to_status: expense.status,
        metadata: { trip_id: trip.id, rule_key: ROAD_FEE_RULE_KEY }
      )

      expense
    end
  end
end

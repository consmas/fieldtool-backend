class Expenses::AutomationController < ApplicationController
  def road_fee_sync
    authorize ExpenseEntry, :run_automation?
    processed = 0
    created = 0

    Trip.where(status: :en_route).find_each do |trip|
      processed += 1
      existing = ExpenseEntry.active.where(trip_id: trip.id, category: :road_expenses).exists?
      Expenses::RoadFeeAutoGenerator.call!(trip:, actor: current_user)
      created += 1 unless existing
    end

    render json: { processed:, created: }
  end

  def fuel_recalculate
    authorize ExpenseEntry, :run_automation?
    scope = Trip.all
    trip_ids = Array(params[:trip_ids] || params.dig(:automation, :trip_ids)).map(&:to_i).uniq
    scope = scope.where(id: trip_ids) if trip_ids.any?

    result = Expenses::FuelRecalculator.call(
      scope: scope,
      actor: current_user,
      price_per_liter_override: params[:price_per_liter] || params.dig(:automation, :price_per_liter)
    )

    render json: {
      processed: result.processed,
      created: result.created,
      updated: result.updated,
      skipped: result.skipped,
      errors: result.errors
    }
  end
end

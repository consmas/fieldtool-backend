class Expenses::AutomationController < ApplicationController
  def road_fee_sync
    authorize ExpenseEntry, :run_automation?
    trip_ids = Trip.where(status: :en_route).pluck(:id)
    trip_ids.each { |trip_id| Expenses::AutoGenerateRoadExpenseJob.perform_later(trip_id, current_user.id) }
    render json: { enqueued: trip_ids.count }
  end

  def fuel_recalculate
    authorize ExpenseEntry, :run_automation?
    trip_ids = Array(params[:trip_ids] || params.dig(:automation, :trip_ids)).map(&:to_i).uniq
    job = Expenses::RecalculateFuelExpenseJob.perform_later(
      trip_ids: (trip_ids.any? ? trip_ids : nil),
      actor_id: current_user.id,
      price_per_liter_override: params[:price_per_liter] || params.dig(:automation, :price_per_liter)
    )
    render json: { enqueued: true, job_id: job.job_id, trip_ids: trip_ids }
  end
end

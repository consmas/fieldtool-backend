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
    target_statuses = Array(params[:target_statuses] || params.dig(:automation, :target_statuses)).presence
    job = Expenses::RecalculateFuelExpenseJob.perform_later(
      trip_ids: (trip_ids.any? ? trip_ids : nil),
      actor_id: current_user.id,
      price_per_liter_override: params[:price_per_liter] || params.dig(:automation, :price_per_liter),
      date_from: params[:date_from] || params.dig(:automation, :date_from),
      date_to: params[:date_to] || params.dig(:automation, :date_to),
      target_statuses: target_statuses
    )
    render json: { enqueued: true, job_id: job.job_id, trip_ids: trip_ids, target_statuses: target_statuses }
  end
end

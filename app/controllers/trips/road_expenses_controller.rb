class Trips::RoadExpensesController < ApplicationController
  def update
    trip = Trip.find(params[:trip_id])
    authorize trip, :manage_logistics?

    trip.update!(
      road_expense_disbursed: road_expense_params[:road_expense_disbursed],
      road_expense_reference: road_expense_params[:road_expense_reference],
      road_expense_payment_status: road_expense_params[:road_expense_payment_status],
      road_expense_payment_method: road_expense_params[:road_expense_payment_method],
      road_expense_payment_reference: road_expense_params[:road_expense_payment_reference],
      road_expense_note: road_expense_params[:road_expense_note],
      road_expense_paid_by: (road_expense_params[:road_expense_payment_status] == "paid" ? current_user : trip.road_expense_paid_by),
      road_expense_paid_at: (road_expense_params[:road_expense_payment_status] == "paid" ? Time.current : trip.road_expense_paid_at)
    )

    TripEvent.create!(
      trip: trip,
      event_type: "road_expense_updated",
      message: "Road expense updated",
      data: road_expense_params.to_h,
      created_by: current_user
    )

    sync_expense_entry!(trip)

    render json: road_expense_payload(trip)
  end

  def receipt
    trip = Trip.find(params[:trip_id])
    authorize trip, :manage_logistics?

    receipt = params[:receipt]
    return render json: { error: ["Receipt is required"] }, status: :unprocessable_entity if receipt.blank?

    trip.road_expense_receipt.attach(receipt)

    TripEvent.create!(
      trip: trip,
      event_type: "road_expense_receipt_uploaded",
      message: "Road expense receipt uploaded",
      data: {},
      created_by: current_user
    )

    render json: road_expense_payload(trip)
  end

  private

  def road_expense_params
    params.require(:road_expense).permit(
      :road_expense_disbursed,
      :road_expense_reference,
      :road_expense_payment_status,
      :road_expense_payment_method,
      :road_expense_payment_reference,
      :road_expense_note
    )
  end

  def road_expense_payload(trip)
    linked_expense = ExpenseEntry.active.where(trip_id: trip.id, category: ExpenseEntry.categories[:road_expenses]).order(created_at: :desc).first

    {
      road_expense_disbursed: trip.road_expense_disbursed,
      road_expense_reference: trip.road_expense_reference,
      road_expense_payment_status: trip.road_expense_payment_status,
      road_expense_payment_method: trip.road_expense_payment_method,
      road_expense_payment_reference: trip.road_expense_payment_reference,
      road_expense_note: trip.road_expense_note,
      road_expense_receipt_attached: trip.road_expense_receipt.attached?,
      expense_entry_id: linked_expense&.id
    }
  end

  def sync_expense_entry!(trip)
    amount = trip.road_expense_disbursed.to_d
    return unless amount.positive?

    expense = ExpenseEntry.active.where(trip_id: trip.id, category: ExpenseEntry.categories[:road_expenses]).order(created_at: :desc).first
    expense ||= ExpenseEntry.new(trip_id: trip.id, category: :road_expenses)

    expense.assign_attributes(
      vehicle_id: trip.vehicle_id,
      driver_id: trip.driver_id,
      amount: amount,
      currency: "GHS",
      description: "Road expense captured from trip logistics",
      reference: trip.road_expense_reference.presence || trip.reference_code.presence || trip.waybill_number,
      payment_method: trip.road_expense_payment_method,
      expense_date: (trip.trip_date || Time.current).in_time_zone,
      is_auto_generated: true,
      auto_rule_key: "trip_road_expense_sync_v1",
      status: (trip.road_expense_payment_status == "paid" ? :paid : :draft),
      paid_by_id: (trip.road_expense_payment_status == "paid" ? current_user.id : nil),
      paid_at: (trip.road_expense_payment_status == "paid" ? Time.current : nil),
      created_by_id: (expense.created_by_id || current_user.id)
    )
    expense.save!
  end
end

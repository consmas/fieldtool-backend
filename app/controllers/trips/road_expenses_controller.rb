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
    {
      road_expense_disbursed: trip.road_expense_disbursed,
      road_expense_reference: trip.road_expense_reference,
      road_expense_payment_status: trip.road_expense_payment_status,
      road_expense_payment_method: trip.road_expense_payment_method,
      road_expense_payment_reference: trip.road_expense_payment_reference,
      road_expense_note: trip.road_expense_note,
      road_expense_receipt_attached: trip.road_expense_receipt.attached?
    }
  end
end

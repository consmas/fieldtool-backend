class Api::V1::Client::DashboardController < Api::V1::Client::BaseController
  def show
    shipments = current_client.shipments
    month_start = Date.current.beginning_of_month

    delivered_this_month = shipments.where(status: "delivered").where(created_at: month_start.beginning_of_day..Time.current).count
    total = shipments.count
    on_time = shipments.where(status: "delivered").where("actual_delivery_at <= requested_delivery_date").count

    render json: {
      active_shipments: shipments.where(status: %w[confirmed picked_up in_transit arriving delivering]).count,
      in_transit: shipments.where(status: "in_transit").count,
      delivered_this_month: delivered_this_month,
      pending_delivery: shipments.where(status: %w[booked confirmed picked_up in_transit arriving delivering]).count,
      total_shipments: total,
      on_time_delivery_rate: total.positive? ? ((on_time.to_d / total.to_d) * 100).round(2) : 0,
      outstanding_balance: current_client.outstanding_balance.to_d,
      recent_shipments: shipments.order(created_at: :desc).limit(5).map { |s| shipment_row(s) },
      upcoming_deliveries: shipments.where.not(requested_delivery_date: nil).order(requested_delivery_date: :asc).limit(5).map { |s| shipment_row(s) }
    }
  end

  private

  def shipment_row(shipment)
    {
      tracking_number: shipment.tracking_number,
      status: shipment.status,
      pickup_address: shipment.pickup_address,
      delivery_address: shipment.delivery_address,
      requested_delivery_date: shipment.requested_delivery_date,
      actual_delivery_at: shipment.actual_delivery_at
    }
  end
end

class Api::V1::Admin::WebhooksController < ApplicationController
  def stats
    authorize :webhook_admin, :stats?

    deliveries = WebhookDelivery.all
    render json: {
      subscriptions: {
        total: WebhookSubscription.count,
        active: WebhookSubscription.where(is_active: true).count,
        inactive: WebhookSubscription.where(is_active: false).count
      },
      delivery_success_rate: {
        last_24h: success_rate(deliveries.where("created_at >= ?", 24.hours.ago)),
        last_7d: success_rate(deliveries.where("created_at >= ?", 7.days.ago)),
        last_30d: success_rate(deliveries.where("created_at >= ?", 30.days.ago))
      },
      top_failing_subscriptions: WebhookSubscription.order(failure_count: :desc).limit(10).pluck(:id, :url, :failure_count).map { |id, url, count| { id: id, url: url, failure_count: count } },
      event_type_distribution: deliveries.group(:event_type).count
    }
  end

  def subscriptions
    authorize :webhook_admin, :subscriptions?

    scope = WebhookSubscription.order(created_at: :desc)
    scope = scope.where(is_active: ActiveModel::Type::Boolean.new.cast(params[:is_active])) if params[:is_active].present?
    scope = scope.where("failure_count >= ?", params[:failure_count_gte].to_i) if params[:failure_count_gte].present?
    scope = scope.where("event_types @> ARRAY[?]::varchar[]", params[:event_type]) if params[:event_type].present?

    render json: scope.limit(200).map { |s|
      {
        id: s.id,
        user_id: s.user_id,
        url: s.url,
        event_types: s.event_types,
        is_active: s.is_active,
        failure_count: s.failure_count,
        last_triggered_at: s.last_triggered_at,
        disabled_at: s.disabled_at
      }
    }
  end

  def reactivate
    authorize :webhook_admin, :reactivate?

    subscription = WebhookSubscription.find(params[:id])
    subscription.update!(is_active: true, failure_count: 0, disabled_at: nil)

    render json: { id: subscription.id, is_active: subscription.is_active, failure_count: subscription.failure_count }
  end

  private

  def success_rate(scope)
    total = scope.count
    return 0 if total <= 0

    ((scope.where(status: "delivered").count.to_d / total.to_d) * 100).round(2)
  end
end

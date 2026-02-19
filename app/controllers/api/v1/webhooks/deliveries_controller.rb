class Api::V1::Webhooks::DeliveriesController < ApplicationController
  def index
    authorize WebhookDelivery
    scope = apply_filters(policy_scope(WebhookDelivery)).order(created_at: :desc)
    scope = scope.limit(limit_param).offset(offset_param)

    render json: scope.map { |d| delivery_payload(d) }
  end

  def retry
    delivery = WebhookDelivery.find(params[:id])
    authorize delivery, :retry?

    delivery.update!(status: "pending", next_retry_at: nil, error_message: nil)
    Webhooks::DeliverWebhookJob.perform_later(delivery.id, force: true)

    render json: delivery_payload(delivery)
  end

  private

  def apply_filters(scope)
    scoped = scope
    scoped = scoped.where(webhook_subscription_id: params[:subscription_id]) if params[:subscription_id].present?
    scoped = scoped.where(event_type: params[:event_type]) if params[:event_type].present?
    scoped = scoped.where(status: params[:status]) if params[:status].present?
    scoped = scoped.where("created_at >= ?", Time.zone.parse(params[:date_from])) if params[:date_from].present?
    scoped = scoped.where("created_at <= ?", Time.zone.parse(params[:date_to])) if params[:date_to].present?
    scoped
  end

  def limit_param
    [params.fetch(:limit, 50).to_i, 200].min
  end

  def offset_param
    [params.fetch(:offset, 0).to_i, 0].max
  end

  def delivery_payload(delivery)
    {
      id: delivery.id,
      webhook_subscription_id: delivery.webhook_subscription_id,
      webhook_event_id: delivery.webhook_event_id,
      event_type: delivery.event_type,
      idempotency_key: delivery.idempotency_key,
      status: delivery.status,
      attempts: delivery.attempts,
      max_attempts: delivery.max_attempts,
      last_attempt_at: delivery.last_attempt_at,
      next_retry_at: delivery.next_retry_at,
      response_code: delivery.response_code,
      response_body: delivery.response_body,
      response_duration_ms: delivery.response_duration_ms,
      error_message: delivery.error_message,
      delivered_at: delivery.delivered_at,
      created_at: delivery.created_at,
      updated_at: delivery.updated_at
    }
  end
end

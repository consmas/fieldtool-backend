class Api::V1::Webhooks::SubscriptionsController < ApplicationController
  def index
    authorize WebhookSubscription
    scope = policy_scope(WebhookSubscription).order(created_at: :desc)
    render json: scope.map { |s| subscription_payload(s, include_secret: false) }
  end

  def show
    subscription = find_subscription
    authorize subscription

    recent = policy_scope(WebhookDelivery).where(webhook_subscription_id: subscription.id).order(created_at: :desc).limit(20)
    render json: subscription_payload(subscription, include_secret: false).merge(
      recent_deliveries: recent.map { |d| delivery_payload(d) }
    )
  end

  def create
    subscription = WebhookSubscription.new(subscription_params)
    subscription.user = current_user
    authorize subscription
    subscription.save!

    render json: subscription_payload(subscription, include_secret: true), status: :created
  end

  def update
    subscription = find_subscription
    authorize subscription

    attrs = subscription_params.to_h
    if ActiveModel::Type::Boolean.new.cast(params[:regenerate_secret])
      attrs[:secret] = SecureRandom.hex(32)
    end

    subscription.update!(attrs)
    render json: subscription_payload(subscription, include_secret: false)
  end

  def destroy
    subscription = find_subscription
    authorize subscription

    subscription.soft_delete!
    head :no_content
  end

  def test
    subscription = find_subscription
    authorize subscription, :test?

    event = WebhookEvent.create!(
      event_type: "ping",
      resource_type: "WebhookSubscription",
      resource_id: subscription.id,
      payload: { message: "Test webhook from ConsMas" },
      triggered_by: current_user.id
    )

    delivery = WebhookDelivery.create!(
      webhook_subscription: subscription,
      webhook_event: event,
      event_type: event.event_type,
      idempotency_key: "ping:#{event.id}:#{subscription.id}:#{Time.current.to_i}",
      payload: event.payload,
      status: "pending"
    )

    Webhooks::DeliverWebhookJob.perform_now(delivery.id, force: true)
    delivery.reload

    render json: delivery_payload(delivery)
  end

  private

  def find_subscription
    WebhookSubscription.find(params[:id])
  end

  def subscription_params
    params.require(:subscription).permit(:url, :description, :is_active, metadata: {}, event_types: [])
  end

  def subscription_payload(subscription, include_secret:)
    payload = {
      id: subscription.id,
      url: subscription.url,
      event_types: subscription.event_types,
      is_active: subscription.is_active,
      description: subscription.description,
      metadata: subscription.metadata,
      failure_count: subscription.failure_count,
      last_triggered_at: subscription.last_triggered_at,
      disabled_at: subscription.disabled_at,
      created_at: subscription.created_at,
      updated_at: subscription.updated_at
    }

    payload[:secret] = subscription.secret if include_secret
    payload
  end

  def delivery_payload(delivery)
    {
      id: delivery.id,
      webhook_subscription_id: delivery.webhook_subscription_id,
      event_type: delivery.event_type,
      status: delivery.status,
      attempts: delivery.attempts,
      max_attempts: delivery.max_attempts,
      response_code: delivery.response_code,
      response_body: delivery.response_body,
      error_message: delivery.error_message,
      delivered_at: delivery.delivered_at,
      created_at: delivery.created_at,
      updated_at: delivery.updated_at
    }
  end
end

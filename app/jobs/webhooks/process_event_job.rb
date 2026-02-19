module Webhooks
  class ProcessEventJob < ApplicationJob
    queue_as :default

    retry_on StandardError, wait: :exponentially_longer, attempts: 5

    def perform(webhook_event_id)
      event = WebhookEvent.find_by(id: webhook_event_id)
      return if event.nil?

      subscriptions = WebhookSubscription.active.where("event_types @> ARRAY[?]::varchar[]", event.event_type)
      subscriptions.find_each do |subscription|
        idempotency_key = "#{event.event_type}:#{event.id}:#{subscription.id}"
        delivery = WebhookDelivery.find_or_create_by!(idempotency_key: idempotency_key) do |d|
          d.webhook_subscription = subscription
          d.webhook_event = event
          d.event_type = event.event_type
          d.payload = event.payload
          d.status = "pending"
          d.max_attempts = ENV.fetch("WEBHOOK_MAX_RETRIES", "5").to_i
        end
        Webhooks::DeliverWebhookJob.perform_later(delivery.id) unless delivery.delivered?
      end
    end
  end
end

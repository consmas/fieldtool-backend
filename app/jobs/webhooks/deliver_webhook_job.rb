require "net/http"
require "openssl"
require "ostruct"

module Webhooks
  class DeliverWebhookJob < ApplicationJob
    queue_as :default

    retry_on Net::OpenTimeout, Net::ReadTimeout, wait: :exponentially_longer, attempts: 2

    def perform(delivery_id, force: false)
      delivery = WebhookDelivery.find_by(id: delivery_id)
      return if delivery.nil?
      return if delivery.delivered? && !force

      subscription = delivery.webhook_subscription
      unless subscription&.is_active?
        delivery.update!(status: "skipped", error_message: "subscription_inactive")
        return
      end

      if delivery.next_retry_at.present? && delivery.next_retry_at > Time.current && !force
        return
      end

      attempt_number = delivery.attempts.to_i + 1
      payload_hash = Webhooks::PayloadEnvelopeBuilder.call(
        event: delivery.webhook_event || OpenStruct.new(id: delivery.id, event_type: delivery.event_type, created_at: delivery.created_at, payload: delivery.payload),
        subscription: subscription,
        attempt: attempt_number
      )
      payload_json = payload_hash.to_json
      max_payload_size = ENV.fetch("WEBHOOK_PAYLOAD_MAX_SIZE", 65_536).to_i
      if payload_json.bytesize > max_payload_size
        delivery.update!(
          status: "failed",
          attempts: attempt_number,
          last_attempt_at: Time.current,
          error_message: "payload_too_large"
        )
        return
      end

      timestamp = Time.current.to_i.to_s
      signature = OpenSSL::HMAC.hexdigest(
        ENV.fetch("WEBHOOK_HMAC_ALGORITHM", "sha256").upcase,
        subscription.secret,
        payload_json
      )

      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      response = perform_post(subscription.url, payload_json, signature, timestamp)
      duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round

      attrs = {
        attempts: attempt_number,
        last_attempt_at: Time.current,
        response_code: response.code.to_i,
        response_body: response.body.to_s.first(1024),
        response_duration_ms: duration_ms,
        error_message: nil
      }

      if response.code.to_i.between?(200, 299)
        delivery.update!(attrs.merge(status: "delivered", delivered_at: Time.current, next_retry_at: nil))
        subscription.update!(failure_count: 0, last_triggered_at: Time.current)
      else
        handle_failure(delivery, subscription, "non_success_http_status", attrs)
      end
    rescue StandardError => e
      attrs = {
        attempts: delivery.attempts.to_i + 1,
        last_attempt_at: Time.current,
        error_message: e.message.to_s.truncate(500)
      }
      handle_failure(delivery, subscription, e.message, attrs)
      Webhooks::DeliveryFailureHandler.record!(delivery: delivery, error: e)
    end

    private

    def perform_post(url, payload_json, signature, timestamp)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = ENV.fetch("WEBHOOK_CONNECT_TIMEOUT", 5).to_i
      http.read_timeout = ENV.fetch("WEBHOOK_READ_TIMEOUT", 5).to_i

      request = Net::HTTP::Post.new(uri.request_uri)
      request["Content-Type"] = "application/json"
      request["X-ConsMas-Signature"] = "sha256=#{signature}"
      request["X-ConsMas-Timestamp"] = timestamp
      request["User-Agent"] = "ConsMas-Webhook/1.0"
      request.body = payload_json

      http.request(request)
    end

    def handle_failure(delivery, subscription, reason, attrs)
      max_attempts = delivery.max_attempts.to_i.positive? ? delivery.max_attempts.to_i : ENV.fetch("WEBHOOK_MAX_RETRIES", "5").to_i
      attempts = attrs[:attempts].to_i

      if attempts < max_attempts
        delay_seconds = (2**attempts) * 30
        next_retry_at = Time.current + delay_seconds.seconds
        delivery.update!(attrs.merge(status: "retrying", next_retry_at: next_retry_at))
        self.class.set(wait_until: next_retry_at).perform_later(delivery.id)
      else
        delivery.update!(attrs.merge(status: "failed", next_retry_at: nil))
        new_failure_count = subscription.failure_count.to_i + 1
        update_attrs = { failure_count: new_failure_count }
        threshold = ENV.fetch("WEBHOOK_CIRCUIT_BREAKER_THRESHOLD", "10").to_i
        if new_failure_count >= threshold
          update_attrs[:is_active] = false
          update_attrs[:disabled_at] = Time.current
        end
        subscription.update!(update_attrs)
      end

      Rails.logger.warn("[WebhookDeliveryFailure] delivery_id=#{delivery.id} reason=#{reason}")
    end
  end
end

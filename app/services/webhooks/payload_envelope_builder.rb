module Webhooks
  class PayloadEnvelopeBuilder
    API_VERSION = "2025-01-01".freeze

    def self.call(event:, subscription:, attempt: 1)
      {
        id: "wh_evt_#{event.id}",
        event_type: event.event_type,
        api_version: API_VERSION,
        created_at: event.created_at&.iso8601,
        data: event.payload,
        metadata: {
          delivery_attempt: attempt,
          subscription_id: "sub_#{subscription.id}"
        }
      }
    end
  end
end

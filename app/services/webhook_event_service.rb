class WebhookEventService
  def self.emit(event_type, resource:, payload:, triggered_by: nil)
    raise ArgumentError, "Unsupported webhook event type: #{event_type}" unless Webhooks::EventTypeRegistry.supported?(event_type)

    event = WebhookEvent.create!(
      event_type: event_type,
      resource_type: resource&.class&.name,
      resource_id: resource&.id,
      payload: payload,
      triggered_by: triggered_by&.id
    )

    Webhooks::ProcessEventJob.perform_later(event.id)
    event
  end
end

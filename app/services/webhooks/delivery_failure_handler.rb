module Webhooks
  class DeliveryFailureHandler
    def self.record!(delivery:, error:)
      FailedJob.create!(
        job_class: "Webhooks::DeliverWebhookJob",
        queue_name: "default",
        arguments: [delivery.id],
        error_class: error.class.name,
        error_message: error.message.to_s.truncate(500),
        backtrace: Array(error.backtrace).first(20).join("\n"),
        status: "failed",
        failed_at: Time.current,
        context: "webhook_delivery"
      )
    end
  end
end

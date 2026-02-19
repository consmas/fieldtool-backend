module Maintenance
  class WebhookCleanupJob < ApplicationJob
    queue_as :low

    def perform(retention_days = 30)
      cutoff = retention_days.to_i.days.ago
      WebhookDelivery.where("created_at < ?", cutoff).delete_all
    end
  end
end

class WebhookDelivery < ApplicationRecord
  STATUSES = %w[pending delivered failed retrying skipped].freeze

  belongs_to :webhook_subscription
  belongs_to :webhook_event, optional: true

  validates :event_type, :idempotency_key, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :idempotency_key, uniqueness: true

  scope :pending_retry, -> { where(status: %w[pending retrying]).where("next_retry_at IS NULL OR next_retry_at <= ?", Time.current) }

  def delivered?
    status == "delivered"
  end

  def failed?
    status == "failed"
  end

  def retrying?
    status == "retrying"
  end
end

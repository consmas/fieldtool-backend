class WebhookSubscription < ApplicationRecord
  belongs_to :user
  has_many :webhook_deliveries, dependent: :destroy

  scope :active, -> { where(is_active: true, deleted_at: nil) }

  validates :url, presence: true
  validates :secret, presence: true
  validate :event_types_supported
  validate :https_url_in_production

  before_validation :ensure_secret

  def deactivate!
    update!(is_active: false, disabled_at: Time.current)
  end

  def soft_delete!
    update!(is_active: false, deleted_at: Time.current)
  end

  def subscribed_to?(event_type)
    event_types.include?(event_type.to_s)
  end

  def regenerate_secret!
    update!(secret: SecureRandom.hex(32))
  end

  private

  def ensure_secret
    self.secret ||= SecureRandom.hex(32)
  end

  def event_types_supported
    invalid = Array(event_types).map(&:to_s) - Webhooks::EventTypeRegistry::EVENTS.keys
    errors.add(:event_types, "contains unsupported event types: #{invalid.join(', ')}") if invalid.any?
  end

  def https_url_in_production
    return if url.blank?
    return unless ActiveModel::Type::Boolean.new.cast(ENV.fetch("WEBHOOK_ENFORCE_HTTPS", Rails.env.production?))

    uri = URI.parse(url)
    errors.add(:url, "must use https") unless uri.scheme == "https"
  rescue URI::InvalidURIError
    errors.add(:url, "is invalid")
  end
end

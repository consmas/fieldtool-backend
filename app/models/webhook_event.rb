class WebhookEvent < ApplicationRecord
  belongs_to :triggered_by_user, class_name: "User", foreign_key: :triggered_by, optional: true
  has_many :webhook_deliveries, dependent: :nullify

  validates :event_type, presence: true
  validates :payload, presence: true
end

class Shipment < ApplicationRecord
  CLIENT_STATUS_MAP = {
    "draft" => "booked",
    "planned" => "booked",
    "assigned" => "confirmed",
    "inspecting" => "confirmed",
    "loading" => "picked_up",
    "loaded" => "picked_up",
    "en_route" => "in_transit",
    "arrived" => "arriving",
    "at_destination" => "arriving",
    "offloading" => "delivering",
    "offloaded" => "delivering",
    "completed" => "delivered",
    "cancelled" => "cancelled"
  }.freeze

  belongs_to :trip
  belongs_to :client
  belongs_to :invoice, optional: true

  has_many :shipment_events, dependent: :destroy
  has_many :invoice_line_items, dependent: :nullify

  validates :tracking_number, :tracking_link_token, :status, presence: true
  validates :tracking_number, :tracking_link_token, uniqueness: true

  scope :tracking_active, -> { where(is_tracking_enabled: true).where("tracking_link_expires_at IS NULL OR tracking_link_expires_at > ?", Time.current) }
end

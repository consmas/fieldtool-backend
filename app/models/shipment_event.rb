class ShipmentEvent < ApplicationRecord
  belongs_to :shipment

  validates :event_type, :title, presence: true
end

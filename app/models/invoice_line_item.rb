class InvoiceLineItem < ApplicationRecord
  belongs_to :invoice
  belongs_to :shipment, optional: true

  validates :description, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_price, numericality: { greater_than_or_equal_to: 0 }

  before_validation :compute_total

  private

  def compute_total
    self.total = quantity.to_d * unit_price.to_d
  end
end

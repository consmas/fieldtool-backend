class Invoice < ApplicationRecord
  STATUSES = %w[draft sent viewed paid partial overdue cancelled].freeze

  belongs_to :client
  has_many :invoice_line_items, dependent: :destroy
  has_many :shipments, dependent: :nullify

  validates :invoice_number, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  before_validation :recalculate_totals

  def recalculate_totals
    self.subtotal = invoice_line_items.sum(:total).to_d
    self.tax_amount = (subtotal.to_d * (tax_rate.to_d / 100)).round(2)
    self.total_amount = subtotal.to_d + tax_amount.to_d
    self.balance_due = total_amount.to_d - amount_paid.to_d
  end
end

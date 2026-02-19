class MaintenanceVendor < ApplicationRecord
  has_many :work_orders, foreign_key: :vendor_id, dependent: :nullify, inverse_of: :vendor

  scope :active, -> { where(is_active: true) }

  validates :name, presence: true
  validates :rating, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5, allow_nil: true }
end

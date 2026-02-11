class FuelPrice < ApplicationRecord
  belongs_to :updated_by, class_name: "User", optional: true

  validates :price_per_liter, presence: true
  validates :effective_at, presence: true
end

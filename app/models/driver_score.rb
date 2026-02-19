class DriverScore < ApplicationRecord
  PERIOD_TYPES = %w[weekly monthly].freeze
  TRENDS = %w[improving stable declining].freeze

  belongs_to :driver_profile

  validates :period_type, inclusion: { in: PERIOD_TYPES }
  validates :trend, inclusion: { in: TRENDS }
end

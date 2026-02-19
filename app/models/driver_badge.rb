class DriverBadge < ApplicationRecord
  belongs_to :driver_profile

  validates :badge_type, :title, :scoring_period, presence: true
end

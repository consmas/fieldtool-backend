class DeviceToken < ApplicationRecord
  PLATFORMS = %w[android ios web].freeze

  belongs_to :user

  scope :active, -> { where(is_active: true) }

  validates :token, presence: true, uniqueness: true
  validates :platform, inclusion: { in: PLATFORMS }
end

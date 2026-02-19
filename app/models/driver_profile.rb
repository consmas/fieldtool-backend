class DriverProfile < ApplicationRecord
  SCORE_TIERS = %w[platinum gold silver bronze probation].freeze
  STATUSES = %w[active on_leave suspended terminated].freeze

  belongs_to :user
  has_many :driver_documents, dependent: :destroy
  has_many :driver_scores, dependent: :destroy
  has_many :driver_badges, dependent: :destroy

  validates :score_tier, inclusion: { in: SCORE_TIERS }
  validates :status, inclusion: { in: STATUSES }
end

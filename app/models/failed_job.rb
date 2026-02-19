class FailedJob < ApplicationRecord
  STATUSES = %w[failed retried resolved].freeze

  validates :job_class, :failed_at, :status, presence: true
  validates :status, inclusion: { in: STATUSES }
end

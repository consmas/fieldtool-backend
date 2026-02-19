class WorkOrderComment < ApplicationRecord
  COMMENT_TYPES = %w[note status_change system].freeze

  belongs_to :work_order
  belongs_to :user

  validates :comment, presence: true
  validates :comment_type, inclusion: { in: COMMENT_TYPES }
end

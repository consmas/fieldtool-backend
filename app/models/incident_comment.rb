class IncidentComment < ApplicationRecord
  COMMENT_TYPES = %w[note status_change investigation_update system].freeze

  belongs_to :incident
  belongs_to :user

  validates :comment, presence: true
  validates :comment_type, inclusion: { in: COMMENT_TYPES }
end

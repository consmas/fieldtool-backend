class EscalationInstance < ApplicationRecord
  STATUSES = %w[active resolved max_reached cancelled].freeze

  belongs_to :escalation_rule
  belongs_to :notification
  belongs_to :notifiable, polymorphic: true, optional: true
  belongs_to :resolver, class_name: "User", foreign_key: :resolved_by, optional: true

  scope :active, -> { where(status: "active") }

  validates :status, inclusion: { in: STATUSES }
end

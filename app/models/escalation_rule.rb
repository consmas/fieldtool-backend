class EscalationRule < ApplicationRecord
  CONDITION_TYPES = %w[unread_after unactioned_after no_location_after].freeze
  PRIORITIES = %w[critical high normal low].freeze

  belongs_to :escalate_to_user, class_name: "User", optional: true
  has_many :escalation_instances, dependent: :destroy

  scope :active, -> { where(is_active: true) }

  validates :name, :trigger_event, presence: true
  validates :condition_type, inclusion: { in: CONDITION_TYPES }
  validates :condition_minutes, numericality: { greater_than: 0 }
  validates :max_escalations, numericality: { greater_than: 0 }
  validates :escalation_priority, inclusion: { in: PRIORITIES }
end

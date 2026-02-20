class AuditLog < ApplicationRecord
  CATEGORIES = %w[trip expense vehicle driver inspection maintenance compliance incident invoice user system chat fuel].freeze
  SEVERITIES = %w[info warning critical security].freeze

  belongs_to :actor, class_name: "User", optional: true
  belongs_to :auditable, polymorphic: true, optional: true
  belongs_to :associated, polymorphic: true, optional: true

  validates :event_id, :action, :category, :severity, :actor_type, :auditable_type, :auditable_id, :occurred_at, presence: true
  validates :event_id, uniqueness: true
  validates :category, inclusion: { in: CATEGORIES }
  validates :severity, inclusion: { in: SEVERITIES }

  scope :by_category, ->(value) { where(category: value) }
  scope :by_action, ->(value) { where(action: value) }
  scope :by_severity, ->(value) { where(severity: value) }
  scope :by_actor, ->(value) { where(actor_id: value) }
  scope :for_resource, ->(type, id) { where(auditable_type: type.to_s.classify, auditable_id: id) }

  def readonly?
    persisted?
  end

  before_update { raise ActiveRecord::ReadOnlyRecord, "Audit logs are immutable" }
  before_destroy { raise ActiveRecord::ReadOnlyRecord, "Audit logs are immutable" }
end

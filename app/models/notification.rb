class Notification < ApplicationRecord
  CATEGORIES = %w[trip expense maintenance compliance chat system alert].freeze
  PRIORITIES = %w[critical high normal low].freeze

  belongs_to :recipient, class_name: "User"
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :notifiable, polymorphic: true, optional: true

  has_many :escalation_instances, dependent: :destroy

  scope :unread, -> { where(read_at: nil) }
  scope :active_feed, -> { where(archived_at: nil).where("expires_at IS NULL OR expires_at > ?", Time.current) }

  validates :notification_type, presence: true
  validates :category, inclusion: { in: CATEGORIES }
  validates :priority, inclusion: { in: PRIORITIES }
  validates :title, presence: true
end

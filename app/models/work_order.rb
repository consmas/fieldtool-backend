class WorkOrder < ApplicationRecord
  WORK_ORDER_TYPES = %w[preventive corrective emergency inspection].freeze
  STATUSES = %w[draft open in_progress on_hold completed cancelled].freeze
  PRIORITIES = %w[critical high medium low].freeze
  ASSIGNEE_TYPES = %w[internal external_vendor].freeze

  belongs_to :vehicle
  belongs_to :maintenance_schedule, optional: true
  belongs_to :vendor, class_name: "MaintenanceVendor", optional: true
  belongs_to :reporter, class_name: "User", foreign_key: :reported_by, optional: true
  belongs_to :expense_entry, optional: true

  has_many :parts, class_name: "WorkOrderPart", dependent: :destroy, inverse_of: :work_order
  has_many :comments, class_name: "WorkOrderComment", dependent: :destroy, inverse_of: :work_order

  validates :title, presence: true
  validates :work_order_type, inclusion: { in: WORK_ORDER_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :priority, inclusion: { in: PRIORITIES }
  validates :assigned_to_type, inclusion: { in: ASSIGNEE_TYPES }, allow_blank: true
  validates :work_order_number, presence: true, uniqueness: true

  before_validation :set_work_order_number, on: :create
  before_validation :set_odometer_at_creation, on: :create
  before_validation :recalculate_costs

  scope :active, -> { where.not(status: %w[completed cancelled]) }

  def can_transition_to?(new_status)
    allowed = {
      "draft" => %w[open],
      "open" => %w[in_progress cancelled],
      "in_progress" => %w[on_hold completed cancelled],
      "on_hold" => %w[in_progress cancelled],
      "completed" => [],
      "cancelled" => []
    }
    allowed.fetch(status, []).include?(new_status.to_s)
  end

  def transition_status!(new_status:, actor:, notes: nil)
    new_status = new_status.to_s
    raise ArgumentError, "invalid status transition #{status} -> #{new_status}" unless can_transition_to?(new_status)

    transaction do
      old_status = status
      attrs = {
        status: new_status,
        started_at: (new_status == "in_progress" ? Time.current : started_at),
        completed_at: (new_status == "completed" ? Time.current : completed_at)
      }

      if new_status == "completed"
        if actual_cost.blank? && (labor_cost.blank? || parts_cost.blank?)
          raise ArgumentError, "actual_cost or labor_cost + parts_cost is required for completion"
        end

        attrs[:actual_cost] = (actual_cost.presence || labor_cost.to_d + parts_cost.to_d)
        attrs[:downtime_hours] = compute_downtime_hours(attrs[:completed_at])
      end

      update!(attrs)

      comments.create!(
        user: actor,
        comment: notes.presence || "Status changed from #{old_status} to #{new_status}",
        comment_type: "status_change",
        metadata: { from_status: old_status, to_status: new_status }
      )
    end
  end

  def parts_total
    parts.sum(:total_cost).to_d
  end

  private

  def set_work_order_number
    return if work_order_number.present?

    year = Time.current.year
    sequence = (self.class.where("work_order_number LIKE ?", "WO-#{year}-%").count + 1).to_s.rjust(4, "0")
    self.work_order_number = "WO-#{year}-#{sequence}"
  end

  def set_odometer_at_creation
    return if odometer_at_creation.present?

    self.odometer_at_creation = [vehicle.trips.maximum(:end_odometer_km), vehicle.trips.maximum(:start_odometer_km)].compact.max
  end

  def recalculate_costs
    self.parts_cost = parts_total if parts.loaded? || parts.any?
    if actual_cost.blank? && (labor_cost.present? || parts_cost.present?)
      self.actual_cost = labor_cost.to_d + parts_cost.to_d
    end
  end

  def compute_downtime_hours(completed)
    return nil if started_at.blank? || completed.blank?

    (((completed - started_at) / 1.hour).round(2)).to_d
  end
end

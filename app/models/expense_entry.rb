class ExpenseEntry < ApplicationRecord
  CATEGORIES = %w[fuel road_fee salary purchase tires maintenance repair emergency other].freeze
  STATUSES = %w[draft pending approved rejected paid].freeze

  enum :category, CATEGORIES.each_with_index.to_h, prefix: true
  enum :status, STATUSES.each_with_index.to_h, prefix: true

  belongs_to :trip, optional: true
  belongs_to :vehicle, optional: true
  belongs_to :driver, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :approved_by, class_name: "User", optional: true
  belongs_to :paid_by, class_name: "User", optional: true

  has_many :audits, class_name: "ExpenseEntryAudit", dependent: :destroy, inverse_of: :expense_entry

  scope :active, -> { where(deleted_at: nil) }

  before_validation :set_default_expense_date

  validates :category, presence: true
  validates :status, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :unit_cost, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :currency, presence: true
  validates :expense_date, presence: true

  validate :amount_matches_quantity_and_unit_cost
  validate :salary_requires_driver_or_reference
  validate :road_fee_auto_rule_defaults
  validate :single_auto_road_fee_per_trip

  def soft_delete!
    update!(deleted_at: Time.current)
  end

  def submit!
    transition_to!("pending")
  end

  def approve!(by_user:)
    transition_to!("approved", approved_by: by_user, approved_at: Time.current)
  end

  def reject!(reason:)
    metadata_was = metadata || {}
    update!(metadata: metadata_was.merge("rejection_reason" => reason.to_s))
    transition_to!("rejected")
  end

  def mark_paid!(by_user:)
    transition_to!("paid", paid_by: by_user, paid_at: Time.current)
  end

  private

  def transition_to!(new_status, attrs = {})
    return true if status == new_status

    allowed = case status
    when "draft" then %w[pending rejected]
    when "pending" then %w[approved rejected]
    when "approved" then %w[paid rejected]
    when "rejected" then %w[pending]
    else []
    end
    raise ArgumentError, "Invalid status transition #{status} -> #{new_status}" unless allowed.include?(new_status)

    update!(attrs.merge(status: new_status))
  end

  def amount_matches_quantity_and_unit_cost
    return if quantity.blank? || unit_cost.blank? || amount.blank?

    expected = quantity.to_d * unit_cost.to_d
    return if (expected - amount.to_d).abs <= BigDecimal("0.05")

    errors.add(:amount, "must approximately equal quantity * unit_cost")
  end

  def salary_requires_driver_or_reference
    return unless category == "salary"
    return if driver_id.present? || reference.present?

    errors.add(:base, "salary expense requires driver_id or reference")
  end

  def road_fee_auto_rule_defaults
    return unless category == "road_fee" && is_auto_generated?
    return unless auto_rule_key == "road_fee_en_route_v1"

    errors.add(:amount, "must be 100 for auto road fee rule") unless amount.to_d == 100.to_d
    errors.add(:currency, "must be GHS for auto road fee rule") unless currency == "GHS"
  end

  def single_auto_road_fee_per_trip
    return unless category == "road_fee" && is_auto_generated? && auto_rule_key == "road_fee_en_route_v1"
    return if trip_id.blank?

    scope = self.class.active.where(trip_id: trip_id, category: self.class.categories[:road_fee], auto_rule_key: "road_fee_en_route_v1")
    scope = scope.where.not(id: id) if persisted?
    errors.add(:trip_id, "already has auto road fee") if scope.exists?
  end

  def set_default_expense_date
    self.expense_date ||= Time.current
  end
end

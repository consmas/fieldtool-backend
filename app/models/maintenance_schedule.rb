class MaintenanceSchedule < ApplicationRecord
  SCHEDULE_TYPES = %w[mileage time both].freeze
  PRIORITIES = %w[critical high medium low].freeze

  belongs_to :vehicle, optional: true
  belongs_to :creator, class_name: "User", foreign_key: :created_by, optional: true

  has_many :work_orders, dependent: :nullify

  scope :active, -> { where(is_active: true) }

  validates :name, presence: true
  validates :schedule_type, inclusion: { in: SCHEDULE_TYPES }
  validates :priority, inclusion: { in: PRIORITIES }
  validates :mileage_interval_km, numericality: { greater_than: 0, allow_nil: true }
  validates :time_interval_days, numericality: { greater_than: 0, allow_nil: true }
  validates :notify_before_km, numericality: { greater_than_or_equal_to: 0 }
  validates :notify_before_days, numericality: { greater_than_or_equal_to: 0 }

  validate :vehicle_or_vehicle_type_present
  validate :required_interval_by_schedule_type

  def current_odometer_km
    return 0 unless vehicle

    [
      vehicle.trips.maximum(:end_odometer_km),
      vehicle.trips.maximum(:start_odometer_km)
    ].compact.max.to_i
  end

  def km_until_due
    return nil if next_due_km.blank?

    next_due_km - current_odometer_km
  end

  def days_until_due
    return nil if next_due_at.blank?

    (next_due_at.to_date - Date.current).to_i
  end

  def overdue?
    due_by_km = next_due_km.present? && current_odometer_km >= next_due_km
    due_by_time = next_due_at.present? && Time.current >= next_due_at
    due_by_km || due_by_time
  end

  def approaching_due?
    near_km = km_until_due.present? && km_until_due <= notify_before_km
    near_days = days_until_due.present? && days_until_due <= notify_before_days
    near_km || near_days
  end

  def refresh_due_targets!(performed_at:, performed_km:)
    self.last_performed_at = performed_at
    self.last_performed_km = performed_km
    self.next_due_at = time_interval_days.present? ? performed_at + time_interval_days.days : nil
    self.next_due_km = mileage_interval_km.present? ? performed_km.to_i + mileage_interval_km : nil
    save!
  end

  private

  def vehicle_or_vehicle_type_present
    return if vehicle_id.present? || vehicle_type.present?

    errors.add(:base, "vehicle_id or vehicle_type must be provided")
  end

  def required_interval_by_schedule_type
    case schedule_type
    when "mileage"
      errors.add(:mileage_interval_km, "must be present for mileage schedule") if mileage_interval_km.blank?
    when "time"
      errors.add(:time_interval_days, "must be present for time schedule") if time_interval_days.blank?
    when "both"
      errors.add(:mileage_interval_km, "must be present for both schedule") if mileage_interval_km.blank?
      errors.add(:time_interval_days, "must be present for both schedule") if time_interval_days.blank?
    end
  end
end

class Trip < ApplicationRecord
  include Auditable

  STATUS_FLOW = %w[draft assigned loaded en_route arrived offloaded completed].freeze
  TERMINAL_STATUSES = %w[completed cancelled].freeze

  # Keep enum type resolution stable even if production is temporarily behind on migrations.
  attribute :fuel_allocation_payment_mode, :integer
  attribute :road_expense_payment_method, :integer
  attribute :road_expense_payment_status, :integer

  enum :status, {
    draft: 0,
    assigned: 1,
    loaded: 2,
    en_route: 3,
    arrived: 4,
    offloaded: 5,
    completed: 6,
    cancelled: 7
  }, prefix: true

  enum :pod_type, {
    photo: 0,
    e_signature: 1,
    manual: 2
  }, prefix: true

  enum :fuel_payment_mode, {
    cash: 0,
    card: 1,
    credit: 2
  }, prefix: true

  enum :fuel_allocation_payment_mode, {
    cash: 0,
    card: 1,
    credit: 2
  }, prefix: true

  enum :road_expense_payment_method, {
    cash: 0,
    momo: 1,
    bank: 2
  }, prefix: true

  enum :road_expense_payment_status, {
    pending: 0,
    paid: 1,
    rejected: 2
  }, prefix: true

  enum :vehicle_condition_post_trip, {
    good: 0,
    requires_service: 1,
    damaged: 2
  }, prefix: true

  belongs_to :driver, class_name: "User", inverse_of: :assigned_trips
  belongs_to :dispatcher, class_name: "User", optional: true
  belongs_to :vehicle, optional: true
  belongs_to :client, optional: true
  belongs_to :start_odometer_captured_by, class_name: "User", optional: true
  belongs_to :end_odometer_captured_by, class_name: "User", optional: true
  belongs_to :fuel_allocated_by, class_name: "User", optional: true
  belongs_to :road_expense_paid_by, class_name: "User", optional: true

  has_many :location_pings, dependent: :destroy
  has_many :evidence, dependent: :destroy
  has_many :trip_events, dependent: :destroy
  has_many :expense_entries, dependent: :nullify
  has_one :shipment, dependent: :nullify
  has_many :fuel_logs, dependent: :nullify
  has_many :fuel_analysis_records, dependent: :nullify
  has_many :incidents, dependent: :nullify
  has_many :compliance_checks, dependent: :nullify
  has_many :compliance_violations, dependent: :nullify
  has_one :pre_trip_inspection, dependent: :destroy
  has_many :trip_stops, dependent: :destroy
  has_one :chat_thread, dependent: :destroy

  has_one_attached :start_odometer_photo
  has_one_attached :end_odometer_photo
  has_one_attached :client_rep_signature
  has_one_attached :proof_of_fuelling
  has_one_attached :inspector_signature
  has_one_attached :security_signature
  has_one_attached :driver_signature
  has_one_attached :road_expense_receipt

  validates :status, presence: true
  validates :driver, presence: true
  validates :delivery_location_source, inclusion: { in: %w[manual google_autocomplete shared_link geolocation] }, allow_nil: true
  validate :end_odometer_not_less_than_start
  validate :reference_matches_waybill
  validate :delivery_coordinates_pair
  validate :delivery_coordinates_range

  before_validation :sync_reference_with_waybill
  before_validation :sync_truck_reg_no
  after_commit :sync_client_shipment, on: [:create, :update]

  def latest_location
    location_pings.order(recorded_at: :desc).first
  end

  def allowed_next_statuses
    return [] if TERMINAL_STATUSES.include?(status)

    flow_index = STATUS_FLOW.index(status)
    next_status = flow_index ? STATUS_FLOW[flow_index + 1] : nil

    candidates = []
    candidates << next_status if next_status
    candidates << "cancelled"
    candidates
  end

  def can_transition_to?(new_status)
    return false if TERMINAL_STATUSES.include?(status)
    return true if new_status == "cancelled"

    allowed_next_statuses.include?(new_status) && gating_rules_pass?(new_status)
  end

  def transition_to!(new_status, by_user:)
    new_status = new_status.to_s
    unless Trip.statuses.key?(new_status)
      raise ArgumentError, "Unknown status: #{new_status}"
    end

    if new_status == status
      return true
    end

    unless can_transition_to?(new_status)
      errors.add(:status, "cannot transition to #{new_status}")
      return false
    end

    transaction do
      update!(
        status: new_status,
        status_changed_at: Time.current,
        completed_at: (new_status == "completed" ? Time.current : completed_at),
        cancelled_at: (new_status == "cancelled" ? Time.current : cancelled_at)
      )
    end
  end

  def capture_start_odometer!(value_km:, photo:, captured_by:, captured_at: Time.current, note: nil, lat: nil, lng: nil)
    self.start_odometer_km = value_km
    self.start_odometer_captured_at = captured_at
    self.start_odometer_captured_by = captured_by
    self.start_odometer_note = note
    self.start_odometer_lat = lat
    self.start_odometer_lng = lng
    self.start_odometer_photo.attach(photo) if photo
    save!
  end

  def capture_end_odometer!(value_km:, photo:, captured_by:, captured_at: Time.current, note: nil, lat: nil, lng: nil)
    self.end_odometer_km = value_km
    self.end_odometer_captured_at = captured_at
    self.end_odometer_captured_by = captured_by
    self.end_odometer_note = note
    self.end_odometer_lat = lat
    self.end_odometer_lng = lng
    self.end_odometer_photo.attach(photo) if photo
    save!
  end

  private

  def end_odometer_not_less_than_start
    return if start_odometer_km.blank? || end_odometer_km.blank?

    if end_odometer_km < start_odometer_km
      errors.add(:end_odometer_km, "must be greater than or equal to start odometer")
    end
  end

  def sync_reference_with_waybill
    if waybill_number.present? && reference_code.blank?
      self.reference_code = waybill_number
    elsif reference_code.present? && waybill_number.blank?
      self.waybill_number = reference_code
    end
  end

  def reference_matches_waybill
    return if reference_code.blank? || waybill_number.blank?
    return if reference_code == waybill_number

    errors.add(:reference_code, "must match waybill_number")
    errors.add(:waybill_number, "must match reference_code")
  end

  def sync_truck_reg_no
    return unless vehicle
    return if truck_reg_no.present?

    self.truck_reg_no = vehicle.license_plate
  end

  def delivery_coordinates_pair
    return if delivery_lat.present? && delivery_lng.present?
    return if delivery_lat.blank? && delivery_lng.blank?

    if delivery_lat.present? && delivery_lng.blank?
      errors.add(:delivery_lng, "must be present when delivery_lat is provided")
    elsif delivery_lng.present? && delivery_lat.blank?
      errors.add(:delivery_lat, "must be present when delivery_lng is provided")
    end
  end

  def delivery_coordinates_range
    return if delivery_lat.blank? || delivery_lng.blank?

    unless delivery_lat.to_d.between?(-90, 90)
      errors.add(:delivery_lat, "must be between -90 and 90")
    end

    unless delivery_lng.to_d.between?(-180, 180)
      errors.add(:delivery_lng, "must be between -180 and 180")
    end
  end

  def gating_rules_pass?(new_status)
    case new_status
    when "completed"
      start_odometer_km.present? &&
        end_odometer_km.present? &&
        end_odometer_photo.attached? &&
        end_odometer_km.to_d >= start_odometer_km.to_d
    else
      true
    end
  end

  def sync_client_shipment
    return if client_id.blank?

    Shipments::SyncFromTripService.call(self)
  rescue StandardError
    nil
  end
end

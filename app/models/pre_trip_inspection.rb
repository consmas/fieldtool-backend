class PreTripInspection < ApplicationRecord
  CORE_CHECKLIST_TEMPLATE = [
    { code: "vehicle_exterior.lights_indicators_working", label: "Lights & indicators", section: "vehicle_exterior", severity_on_fail: "blocker" },
    { code: "vehicle_exterior.mirrors_windscreen_ok", label: "Mirrors & windscreen", section: "vehicle_exterior", severity_on_fail: "warning" },
    { code: "vehicle_exterior.license_plate_visible", label: "License plate visible", section: "vehicle_exterior", severity_on_fail: "blocker" },
    { code: "vehicle_exterior.no_major_body_damage", label: "No major body damage", section: "vehicle_exterior", severity_on_fail: "warning" },
    { code: "tyres.pressure_all_wheels_ok", label: "Tyre pressure all wheels", section: "tyres", severity_on_fail: "blocker" },
    { code: "tyres.tread_depth_ok", label: "Tread depth", section: "tyres", severity_on_fail: "blocker" },
    { code: "tyres.no_cuts_bulges_exposed_cord", label: "No tyre cuts/bulges/exposed cord", section: "tyres", severity_on_fail: "blocker" },
    { code: "tyres.wheel_nuts_secure", label: "Wheel nuts secure", section: "tyres", severity_on_fail: "blocker" },
    { code: "brakes.service_brake_ok", label: "Service brake", section: "brakes_steering", severity_on_fail: "blocker" },
    { code: "brakes.parking_brake_ok", label: "Parking brake", section: "brakes_steering", severity_on_fail: "blocker" },
    { code: "brakes.air_or_brake_warning_clear", label: "Brake warning clear", section: "brakes_steering", severity_on_fail: "blocker" },
    { code: "steering.steering_response_ok", label: "Steering response", section: "brakes_steering", severity_on_fail: "blocker" },
    { code: "engine.engine_oil_level_ok", label: "Engine oil level", section: "engine_fluids", severity_on_fail: "blocker" },
    { code: "engine.coolant_level_ok", label: "Coolant level", section: "engine_fluids", severity_on_fail: "blocker" },
    { code: "engine.brake_fluid_level_ok", label: "Brake fluid level", section: "engine_fluids", severity_on_fail: "blocker" },
    { code: "engine.no_active_leaks", label: "No active leaks", section: "engine_fluids", severity_on_fail: "blocker" },
    { code: "coupling.kingpin_or_hitch_locked", label: "Kingpin/hitch locked", section: "coupling", severity_on_fail: "blocker" },
    { code: "coupling.air_electrical_lines_connected", label: "Air/electrical lines connected", section: "coupling", severity_on_fail: "blocker" },
    { code: "coupling.trailer_lights_working", label: "Trailer lights", section: "coupling", severity_on_fail: "blocker" },
    { code: "coupling.trailer_legs_raised_locked", label: "Trailer legs raised/locked", section: "coupling", severity_on_fail: "blocker" },
    { code: "safety.fire_extinguisher_present_charged", label: "Fire extinguisher present/charged", section: "safety", severity_on_fail: "blocker" },
    { code: "safety.warning_triangles_present", label: "Warning triangles present", section: "safety", severity_on_fail: "blocker" },
    { code: "safety.first_aid_kit_present", label: "First aid kit present", section: "safety", severity_on_fail: "warning" },
    { code: "safety.seatbelt_driver_ok", label: "Driver seatbelt", section: "safety", severity_on_fail: "blocker" },
    { code: "docs.driver_license_valid", label: "Driver license valid", section: "documents", severity_on_fail: "blocker" },
    { code: "docs.vehicle_registration_present", label: "Vehicle registration present", section: "documents", severity_on_fail: "blocker" },
    { code: "docs.insurance_or_roadworthy_valid", label: "Insurance/roadworthy valid", section: "documents", severity_on_fail: "blocker" },
    { code: "docs.waybill_present", label: "Waybill present", section: "documents", severity_on_fail: "blocker" },
    { code: "load.load_area_ready", label: "Load area ready", section: "load_readiness", severity_on_fail: "blocker" },
    { code: "load.load_secured", label: "Load secured", section: "load_readiness", severity_on_fail: "blocker" },
    { code: "load.weight_within_limit", label: "Weight within limit", section: "load_readiness", severity_on_fail: "blocker" }
  ].freeze
  CORE_CHECKLIST_CODES = CORE_CHECKLIST_TEMPLATE.map { |item| item[:code] }.freeze
  CORE_CHECKLIST_STATUSES = %w[pass fail na].freeze

  enum :load_status, { full: 0, partial: 1 }
  enum :inspection_verification_status, { pending: 0, approved: 1, rejected: 2 }, prefix: true

  belongs_to :trip
  belongs_to :captured_by, class_name: "User"
  belongs_to :inspection_verified_by, class_name: "User", optional: true
  belongs_to :inspection_confirmed_by, class_name: "User", optional: true

  has_one_attached :odometer_photo
  has_one_attached :load_photo
  has_one_attached :waybill_photo
  has_one_attached :inspector_signature
  has_one_attached :inspector_photo

  validates :odometer_value_km, presence: true
  validates :odometer_captured_at, presence: true
  validates :brakes, :tyres, :lights, :mirrors, :horn, :fuel_sufficient, inclusion: { in: [true, false] }
  validates :accepted, inclusion: { in: [true, false] }
  validates :trip_id, uniqueness: true

  validate :odometer_photo_attached
  validate :accepted_at_required_when_accepted
  validate :load_fields_consistency
  validate :core_checklist_structure

  before_validation :normalize_core_checklist

  private

  def odometer_photo_attached
    errors.add(:odometer_photo, "must be attached") unless odometer_photo.attached?
  end

  def accepted_at_required_when_accepted
    return unless accepted && accepted_at.blank?

    errors.add(:accepted_at, "must be present when accepted")
  end

  def load_fields_consistency
    load_fields_touched =
      will_save_change_to_load_area_ready? ||
      will_save_change_to_load_status? ||
      will_save_change_to_load_secured? ||
      will_save_change_to_load_note? ||
      attachment_changes.key?("load_photo")
    return unless load_fields_touched

    errors.add(:load_area_ready, "must be set") if load_area_ready.nil?
    errors.add(:load_status, "must be set") if load_status.nil?
    errors.add(:load_secured, "must be set") if load_secured.nil?
  end

  def normalize_core_checklist
    return if core_checklist.blank?

    normalized = {}
    core_checklist.to_h.each do |code, value|
      code_key = code.to_s
      if value.is_a?(Hash)
        normalized[code_key] = {
          "status" => value["status"] || value[:status],
          "note" => value["note"] || value[:note]
        }.compact
      else
        normalized[code_key] = value.to_s
      end
    end

    self.core_checklist = normalized
  end

  def core_checklist_structure
    return if core_checklist.blank?
    return errors.add(:core_checklist, "must be an object") unless core_checklist.is_a?(Hash)

    unknown_codes = core_checklist.keys - CORE_CHECKLIST_CODES
    errors.add(:core_checklist, "contains unknown item codes: #{unknown_codes.join(', ')}") if unknown_codes.any?

    core_checklist.each do |code, value|
      status = value.is_a?(Hash) ? value["status"] : value
      next if CORE_CHECKLIST_STATUSES.include?(status.to_s)

      errors.add(:core_checklist, "#{code} has invalid status '#{status}'")
    end
  end
end

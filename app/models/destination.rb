class Destination < ApplicationRecord
  before_validation :normalize_rate_fields

  validates :name, presence: true, uniqueness: true
  validates :average_distance_km, :base_km, :base_trip_cost, presence: true
  validates :average_distance_km, :base_trip_cost, numericality: { greater_than_or_equal_to: 0 }
  validates :base_km, numericality: { greater_than: 0 }
  validates :additional_provision_pct, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }, allow_nil: true
  validate :fuel_consumption_present_and_positive

  private

  def normalize_rate_fields
    normalize_additional_provision_pct
    normalize_base_trip_cost
    normalize_kms_per_liter
    normalize_legacy_reference_fields
  end

  def normalize_additional_provision_pct
    return if additional_provision_pct.blank?

    pct = additional_provision_pct.to_d
    self.additional_provision_pct = pct / 100 if pct > 1 && pct <= 100
  end

  def normalize_base_trip_cost
    return unless base_trip_cost.to_d <= 0 && base_price_per_ton.to_d.positive? && tons_per_trip.to_d.positive?

    self.base_trip_cost = (base_price_per_ton.to_d * tons_per_trip.to_d).round(2)
  end

  def normalize_kms_per_liter
    if prioritize_liters_per_km?
      return unless liters_per_km.to_d.positive?

      self.kms_per_liter = (1 / liters_per_km.to_d).round(4)
      return
    end

    if kms_per_liter.to_d <= 0 && liters_per_km.to_d.positive?
      self.kms_per_liter = (1 / liters_per_km.to_d).round(4)
      return
    end

    return unless kms_per_liter.to_d.positive?

    self.liters_per_km = (1 / kms_per_liter.to_d).round(4)
  end

  def normalize_legacy_reference_fields
    self.fuel_price_ref = 0 if fuel_price_ref.blank?
    self.base_price_per_ton = 0 if base_price_per_ton.blank?
    self.tons_per_trip = 0 if tons_per_trip.blank?
  end

  def fuel_consumption_present_and_positive
    if liters_per_km.to_d <= 0 && kms_per_liter.to_d <= 0
      errors.add(:base, "Either liters_per_km or kms_per_liter must be greater than 0")
      return
    end

    if liters_per_km.to_d < 0
      errors.add(:liters_per_km, "must be greater than or equal to 0")
    end

    if kms_per_liter.to_d < 0
      errors.add(:kms_per_liter, "must be greater than or equal to 0")
    end
  end

  def prioritize_liters_per_km?
    return false unless liters_per_km.to_d.positive?

    default_liters = self.class.column_defaults["liters_per_km"].to_d
    default_kms = self.class.column_defaults["kms_per_liter"].to_d

    if persisted?
      liters_changed = will_save_change_to_liters_per_km?
      kms_changed = will_save_change_to_kms_per_liter?
      return true if liters_changed && !kms_changed
      return false if kms_changed && !liters_changed
      return true if liters_changed && kms_changed
    else
      liters_differs_from_default = liters_per_km.to_d != default_liters
      kms_differs_from_default = kms_per_liter.to_d != default_kms
      return true if liters_differs_from_default && !kms_differs_from_default
      return false if kms_differs_from_default && !liters_differs_from_default
      return true if liters_differs_from_default && kms_differs_from_default
    end

    false
  end
end

class FillToFillAnalysisService
  class << self
    def analyze(fuel_log)
      return unless fuel_log.is_full_tank?

      vehicle = fuel_log.vehicle
      previous_full = FuelLog.where(vehicle_id: vehicle.id, is_full_tank: true)
                             .where("fueled_at < ?", fuel_log.fueled_at)
                             .order(fueled_at: :desc)
                             .first
      return if previous_full.nil?

      distance_km = fuel_log.odometer_reading.to_i - previous_full.odometer_reading.to_i
      return if distance_km <= 0

      fuel_consumed = FuelLog.where(vehicle_id: vehicle.id)
                             .where("fueled_at > ? AND fueled_at <= ?", previous_full.fueled_at, fuel_log.fueled_at)
                             .sum(:liters)
                             .to_d
      return if fuel_consumed <= 0

      expected_km_per_liter = vehicle.baseline_km_per_liter.to_d.nonzero? || 4.to_d
      expected_liters = distance_km.to_d / expected_km_per_liter
      actual_km_per_liter = distance_km.to_d / fuel_consumed
      variance_percent = ((fuel_consumed - expected_liters) / expected_liters) * 100
      threshold = vehicle.anomaly_threshold_percent.to_d.nonzero? || 20.to_d
      is_anomaly = variance_percent.abs > threshold

      FuelAnalysisRecord.create!(
        vehicle_id: vehicle.id,
        analysis_type: "fill_to_fill",
        distance_km: distance_km,
        fuel_consumed_liters: fuel_consumed,
        expected_consumption_liters: expected_liters,
        actual_km_per_liter: actual_km_per_liter,
        expected_km_per_liter: expected_km_per_liter,
        variance_percent: variance_percent,
        variance_liters: fuel_consumed - expected_liters,
        anomaly_score: is_anomaly ? [variance_percent.abs, 100].min : 0,
        is_anomaly: is_anomaly,
        anomaly_type: is_anomaly ? classify_type(variance_percent) : nil,
        anomaly_severity: is_anomaly ? classify_severity(variance_percent) : nil,
        possible_causes: is_anomaly ? suggest_causes(variance_percent) : [],
        investigation_status: is_anomaly ? "pending" : nil,
        period_start: previous_full.fueled_at,
        period_end: fuel_log.fueled_at
      )
    end

    private

    def classify_type(variance)
      v = variance.to_d
      return "overconsumption" if v > 20
      return "impossible_reading" if v < -50
      return "underconsumption" if v < -30

      nil
    end

    def classify_severity(variance)
      abs = variance.to_d.abs
      return "critical" if abs > 50
      return "high" if abs > 30
      return "medium" if abs > 20

      "low"
    end

    def suggest_causes(variance)
      v = variance.to_d
      if v > 30
        ["fuel theft", "mechanical issue", "driving behavior", "excessive idling"]
      elsif v > 20
        ["driving behavior", "road conditions", "tire pressure", "load weight"]
      elsif v < -30
        ["data entry error", "odometer discrepancy", "incomplete fuel logging"]
      else
        []
      end
    end
  end
end

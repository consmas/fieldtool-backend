class FuelAnalysisService
  class << self
    def analyze_trip(trip)
      vehicle = trip.vehicle
      return nil if vehicle.nil?
      return nil if vehicle.baseline_km_per_liter.blank?
      return nil if trip.distance_km.to_d <= 0

      expected_liters = trip.distance_km.to_d / vehicle.baseline_km_per_liter.to_d

      actual_liters = FuelLog.where(trip_id: trip.id).sum(:liters).to_d
      actual_liters = trip.fuel_litres_filled.to_d if actual_liters.zero? && trip.respond_to?(:fuel_litres_filled)
      return nil if actual_liters.zero?

      actual_km_per_liter = trip.distance_km.to_d / actual_liters
      variance_percent = ((actual_liters - expected_liters) / expected_liters) * 100
      variance_liters = actual_liters - expected_liters

      threshold = vehicle.anomaly_threshold_percent.to_d.nonzero? || 20.to_d
      is_anomaly = variance_percent.abs > threshold
      anomaly_score = calculate_anomaly_score(variance_percent, trip, vehicle)
      anomaly_type, severity, causes = classify_anomaly(variance_percent)

      record = FuelAnalysisRecord.create!(
        vehicle_id: vehicle.id,
        trip_id: trip.id,
        driver_id: trip.driver_id,
        analysis_type: "per_trip",
        distance_km: trip.distance_km,
        fuel_consumed_liters: actual_liters,
        expected_consumption_liters: expected_liters,
        actual_km_per_liter: actual_km_per_liter,
        expected_km_per_liter: vehicle.baseline_km_per_liter,
        variance_percent: variance_percent,
        variance_liters: variance_liters,
        anomaly_score: anomaly_score,
        is_anomaly: is_anomaly,
        anomaly_type: (is_anomaly ? anomaly_type : nil),
        anomaly_severity: (is_anomaly ? severity : nil),
        possible_causes: causes,
        investigation_status: (is_anomaly ? "pending" : nil),
        period_start: trip.started_at,
        period_end: trip.completed_at
      )

      update_vehicle_averages(vehicle)

      if is_anomaly
        NotificationService.notify(
          notification_type: "fuel.anomaly_detected",
          recipients: ["admin", "finance"],
          notifiable: record,
          data: {
            trip_number: trip.reference_code || "TRIP-#{trip.id}",
            expected_liters: expected_liters.round(1),
            actual_liters: actual_liters.round(1),
            expected_km_per_liter: vehicle.baseline_km_per_liter.to_d.round(2),
            actual_km_per_liter: actual_km_per_liter.to_d.round(2)
          },
          priority: severity == "critical" ? "critical" : "high"
        )
      end

      record
    end

    def calculate_anomaly_score(variance_percent, trip, vehicle)
      base = [variance_percent.abs.to_d, 50.to_d].min
      distance_factor = trip.distance_km.to_d < 50 ? -10 : 0
      recent = vehicle.fuel_analysis_records.where(analysis_type: "per_trip").order(created_at: :desc).limit(20)
      history_avg = recent.any? ? recent.sum { |r| r.variance_percent.to_d.abs } / recent.size : 0.to_d
      history_factor = if history_avg.positive? && variance_percent.abs > history_avg * 2
                        25
                      elsif history_avg.positive? && variance_percent.abs > history_avg
                        15
                      else
                        0
                      end

      (base + distance_factor + history_factor).clamp(0, 100)
    end

    def classify_anomaly(variance_percent)
      variance = variance_percent.to_d
      if variance > 50
        ["overconsumption", "critical", ["possible fuel theft", "major mechanical issue", "incorrect odometer reading"]]
      elsif variance > 30
        ["overconsumption", "high", ["fuel theft", "mechanical issue", "heavy load", "poor road conditions", "excessive idling"]]
      elsif variance > 20
        ["overconsumption", "medium", ["driving behavior", "traffic congestion", "tire pressure", "vehicle age"]]
      elsif variance < -50
        ["impossible_reading", "high", ["data entry error", "odometer tampering", "incorrect fuel quantity logged"]]
      elsif variance < -30
        ["underconsumption", "medium", ["incorrect fuel log", "partial refueling recorded as full", "odometer discrepancy"]]
      else
        [nil, "low", []]
      end
    end

    def update_vehicle_averages(vehicle)
      recent = vehicle.fuel_analysis_records.where(analysis_type: "per_trip").order(created_at: :desc).limit(50)
      return if recent.empty?

      total_distance = recent.sum { |r| r.distance_km.to_d }
      total_fuel = recent.sum { |r| r.fuel_consumed_liters.to_d }
      avg = total_fuel.positive? ? (total_distance / total_fuel) : 0

      vehicle.update!(
        average_km_per_liter: avg.round(2),
        total_fuel_consumed_liters: vehicle.fuel_logs.sum(:liters).to_d,
        total_fuel_cost: vehicle.fuel_logs.sum(:total_cost).to_d
      )
    end
  end
end

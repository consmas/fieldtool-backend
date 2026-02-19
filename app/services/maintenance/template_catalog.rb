module Maintenance
  class TemplateCatalog
    TEMPLATES = {
      "standard_truck" => [
        { name: "Engine Oil Change", schedule_type: "both", mileage_interval_km: 5000, time_interval_days: 90, priority: "high", notify_before_km: 500, notify_before_days: 7 },
        { name: "Oil Filter Replacement", schedule_type: "mileage", mileage_interval_km: 10_000, priority: "high", notify_before_km: 1000 },
        { name: "Air Filter Replacement", schedule_type: "mileage", mileage_interval_km: 20_000, priority: "medium", notify_before_km: 2000 },
        { name: "Fuel Filter Replacement", schedule_type: "mileage", mileage_interval_km: 30_000, priority: "medium", notify_before_km: 3000 },
        { name: "Tire Rotation", schedule_type: "mileage", mileage_interval_km: 10_000, priority: "medium", notify_before_km: 1000 },
        { name: "Brake Inspection", schedule_type: "both", mileage_interval_km: 15_000, time_interval_days: 180, priority: "critical", notify_before_km: 2000, notify_before_days: 14 },
        { name: "Transmission Fluid", schedule_type: "mileage", mileage_interval_km: 50_000, priority: "high", notify_before_km: 5000 },
        { name: "Coolant Flush", schedule_type: "both", mileage_interval_km: 50_000, time_interval_days: 365, priority: "medium", notify_before_km: 5000, notify_before_days: 30 },
        { name: "Battery Check", schedule_type: "time", time_interval_days: 180, priority: "medium", notify_before_days: 14 },
        { name: "Full Vehicle Inspection", schedule_type: "both", mileage_interval_km: 25_000, time_interval_days: 365, priority: "high", notify_before_km: 2000, notify_before_days: 30 }
      ],
      "tanker" => [
        { name: "Tank Integrity Inspection", schedule_type: "both", mileage_interval_km: 20_000, time_interval_days: 180, priority: "critical", notify_before_km: 2000, notify_before_days: 14 },
        { name: "Valve and Hose Check", schedule_type: "mileage", mileage_interval_km: 10_000, priority: "high", notify_before_km: 1000 },
        { name: "Emergency Shutoff Test", schedule_type: "time", time_interval_days: 90, priority: "critical", notify_before_days: 7 }
      ]
    }.freeze

    def self.fetch(template_name)
      TEMPLATES[template_name.to_s]
    end

    def self.keys
      TEMPLATES.keys
    end
  end
end

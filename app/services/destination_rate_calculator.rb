class DestinationRateCalculator
  def initialize(destination:, fuel_price_current:, additional_km: 0)
    @destination = destination
    @fuel_price_current = fuel_price_current.to_d
    @additional_km = additional_km.to_d
  end

  def call
    base_km = @destination.base_km.to_d
    base_trip_cost = @destination.base_trip_cost.to_d
    liters_per_km = @destination.liters_per_km.to_d

    total_km = @destination.average_distance_km.to_d
    extra_km = [total_km - base_km, 0].max
    fuel_cost_per_km = @fuel_price_current * liters_per_km
    extra_distance_charge = extra_km * fuel_cost_per_km

    extra_stop_charge = @additional_km * fuel_cost_per_km
    final_trip_cost = base_trip_cost + extra_distance_charge + extra_stop_charge

    {
      base_trip_cost: base_trip_cost,
      base_km: base_km,
      total_km: total_km,
      liters_per_km: liters_per_km,
      fuel_cost_per_km: fuel_cost_per_km,
      extra_distance_charge: extra_distance_charge,
      extra_stop_charge: extra_stop_charge,
      final_trip_cost: final_trip_cost
    }
  end
end

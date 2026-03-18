class DestinationRateCalculator
  def initialize(destination:, fuel_price_current:, additional_km: 0)
    @destination = destination
    @fuel_price_current = fuel_price_current.to_d
    @additional_km = additional_km.to_d
  end

  def call
    base_km         = @destination.base_km.to_d
    avg_km          = @destination.average_distance_km.to_d
    provision_pct   = @destination.additional_provision_pct.to_d
    kms_per_liter   = @destination.kms_per_liter.to_d
    other_cost      = @destination.base_trip_cost.to_d

    # Step 1: Base km fuel cost with provision buffer (e.g. 100 × 1.25 = 125 km → 41.67 L → 599 GHS)
    base_total_kms  = base_km * (1 + provision_pct)
    base_liters     = kms_per_liter.positive? ? (base_total_kms / kms_per_liter) : 0.to_d
    base_fuel_cost  = (base_liters * @fuel_price_current).round(2)

    # Step 2: Extra km beyond base from average route distance (e.g. Kumasi 520 - 100 = 420 km extra)
    route_extra_km  = [avg_km - base_km, 0.to_d].max
    extra_total_kms = route_extra_km * (1 + provision_pct)
    extra_liters    = kms_per_liter.positive? ? (extra_total_kms / kms_per_liter) : 0.to_d
    extra_fuel_cost = (extra_liters * @fuel_price_current).round(2)

    # Step 3: Additional km from on-trip extra stops (no provision applied)
    stop_liters     = kms_per_liter.positive? ? (@additional_km / kms_per_liter) : 0.to_d
    stop_fuel_cost  = (stop_liters * @fuel_price_current).round(2)

    # Step 4: expected rate = base fuel + extra route fuel + other costs + stop fuel
    expected_rate   = (base_fuel_cost + extra_fuel_cost + other_cost + stop_fuel_cost).round(2)

    {
      base_km:                  base_km,
      average_distance_km:      avg_km,
      route_extra_km:           route_extra_km.round(2),
      additional_provision_pct: provision_pct,
      kms_per_liter:            kms_per_liter,
      fuel_price:               @fuel_price_current,
      base_fuel_cost:           base_fuel_cost,
      extra_fuel_cost:          extra_fuel_cost,
      other_cost:               other_cost,
      extra_km:                 @additional_km,
      stop_fuel_cost:           stop_fuel_cost,
      expected_rate:            expected_rate
    }
  end
end

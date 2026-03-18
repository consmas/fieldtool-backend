class DestinationRateCalculator
  def initialize(destination:, fuel_price_current:, additional_km: 0)
    @destination = destination
    @fuel_price_current = fuel_price_current.to_d
    @additional_km = additional_km.to_d
  end

  def call
    base_km         = @destination.base_km.to_d
    provision_pct   = @destination.additional_provision_pct.to_d
    kms_per_liter   = @destination.kms_per_liter.to_d
    other_cost      = @destination.base_trip_cost.to_d

    # Step 1: apply provision to base km  (e.g. 100 × 1.25 = 125)
    total_kms       = base_km * (1 + provision_pct)

    # Step 2: liters required for the trip  (e.g. 125 ÷ 3 = 41.67)
    liters_per_trip = kms_per_liter.positive? ? (total_kms / kms_per_liter) : 0.to_d

    # Step 3: fuel cost for the trip  (e.g. 41.67 × 14.38 ≈ 599)
    fuel_cost       = (liters_per_trip * @fuel_price_current).round(2)

    # Step 4: extra fuel cost for additional km (extra stops)
    extra_liters    = kms_per_liter.positive? ? (@additional_km / kms_per_liter) : 0.to_d
    extra_fuel_cost = (extra_liters * @fuel_price_current).round(2)

    # Step 5: expected rate = fuel cost + other costs  (e.g. 599 + 3151 = 3750)
    expected_rate   = (fuel_cost + other_cost + extra_fuel_cost).round(2)

    {
      base_km:                  base_km,
      additional_provision_pct: provision_pct,
      total_kms:                total_kms.round(2),
      kms_per_liter:            kms_per_liter,
      liters_per_trip:          liters_per_trip.round(2),
      fuel_price:               @fuel_price_current,
      fuel_cost:                fuel_cost,
      other_cost:               other_cost,
      extra_km:                 @additional_km,
      extra_fuel_cost:          extra_fuel_cost,
      expected_rate:            expected_rate
    }
  end
end

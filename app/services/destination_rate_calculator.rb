class DestinationRateCalculator
  def initialize(destination:, fuel_price_current:, additional_km: 0)
    @destination = destination
    @fuel_price_current = fuel_price_current.to_d
    @additional_km = additional_km.to_d
  end

  def call
    base_km = @destination.base_km.to_d
    total_km = @destination.average_distance_km.to_d
    base_rate = @destination.base_trip_cost.to_d
    litres_per_km = resolved_litres_per_km
    route_extra_km = [total_km - base_km, 0.to_d].max
    total_extra_km = route_extra_km + @additional_km
    additional_fee = (total_extra_km * @fuel_price_current * litres_per_km).round(2)
    expected_rate = (base_rate + additional_fee).round(2)

    {
      base_km: base_km,
      average_distance_km: total_km,
      route_extra_km: route_extra_km.round(2),
      extra_km: @additional_km.round(2),
      total_extra_km: total_extra_km.round(2),
      fuel_price: @fuel_price_current,
      litres_per_km: litres_per_km,
      base_rate: base_rate,
      additional_fee: additional_fee,
      expected_rate: expected_rate
    }
  end

  private

  def resolved_litres_per_km
    litres_per_km = @destination.respond_to?(:liters_per_km) ? @destination.liters_per_km.to_d : 0.to_d
    return litres_per_km if litres_per_km.positive?

    kms_per_liter = @destination.kms_per_liter.to_d
    return 0.to_d unless kms_per_liter.positive?

    (1 / kms_per_liter).to_d
  end
end

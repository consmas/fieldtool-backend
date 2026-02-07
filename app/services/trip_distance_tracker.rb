require "net/http"
require "json"

class TripDistanceTracker
  GOOGLE_ROADS_ENDPOINT = "https://roads.googleapis.com/v1/snapToRoads".freeze

  def initialize(trip)
    @trip = trip
  end

  def add_ping!(ping)
    previous = previous_ping(ping)
    return if previous.nil?

    from_lat, from_lng = snapped_point_for(previous)
    to_lat, to_lng = snapped_point_for(ping, fallback: [ping.lat, ping.lng], previous_point: [from_lat, from_lng])

    segment_km = haversine_km(from_lat, from_lng, to_lat, to_lng)
    return if segment_km.nan?

    @trip.update!(
      distance_km: @trip.distance_km.to_d + segment_km,
      distance_computed_at: Time.current,
      last_snapped_lat: to_lat,
      last_snapped_lng: to_lng
    )
  end

  private

  def previous_ping(ping)
    @trip.location_pings.where.not(id: ping.id).order(recorded_at: :desc).first
  end

  def snapped_point_for(ping, fallback: nil, previous_point: nil)
    if previous_point.nil? && @trip.last_snapped_lat && @trip.last_snapped_lng
      return [@trip.last_snapped_lat.to_f, @trip.last_snapped_lng.to_f]
    end

    if google_roads_key.present?
      snapped = snap_points(previous_point || [ping.lat, ping.lng], [ping.lat, ping.lng])
      return snapped if snapped
    end

    fallback || [ping.lat, ping.lng]
  end

  def snap_points(from_point, to_point)
    return nil if from_point.nil? || to_point.nil?

    path = [from_point, to_point].map { |lat, lng| "#{lat},#{lng}" }.join("|")
    uri = URI(GOOGLE_ROADS_ENDPOINT)
    uri.query = URI.encode_www_form(path: path, interpolate: false, key: google_roads_key)

    response = Net::HTTP.get_response(uri)
    return nil unless response.is_a?(Net::HTTPSuccess)

    body = JSON.parse(response.body)
    snapped_points = body["snappedPoints"] || []
    return nil if snapped_points.empty?

    last = snapped_points.last["location"]

    [last["latitude"].to_f, last["longitude"].to_f]
  rescue StandardError
    nil
  end

  def google_roads_key
    ENV["GOOGLE_ROADS_API_KEY"]
  end

  def haversine_km(lat1, lon1, lat2, lon2)
    rad_per_deg = Math::PI / 180
    r_km = 6371

    dlat_rad = (lat2 - lat1) * rad_per_deg
    dlon_rad = (lon2 - lon1) * rad_per_deg

    lat1_rad = lat1 * rad_per_deg
    lat2_rad = lat2 * rad_per_deg

    a = Math.sin(dlat_rad / 2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad / 2)**2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

    r_km * c
  end
end

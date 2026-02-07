class AddDistanceTrackingToTrips < ActiveRecord::Migration[8.0]
  def change
    change_table :trips, bulk: true do |t|
      t.decimal :distance_km, precision: 12, scale: 3, default: 0.0, null: false
      t.datetime :distance_computed_at
      t.decimal :last_snapped_lat, precision: 10, scale: 6
      t.decimal :last_snapped_lng, precision: 10, scale: 6
    end
  end
end

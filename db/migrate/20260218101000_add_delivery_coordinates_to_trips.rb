class AddDeliveryCoordinatesToTrips < ActiveRecord::Migration[8.0]
  def change
    add_column :trips, :delivery_place_id, :string
    add_column :trips, :delivery_lat, :decimal, precision: 10, scale: 6
    add_column :trips, :delivery_lng, :decimal, precision: 10, scale: 6
    add_column :trips, :delivery_map_url, :string
    add_column :trips, :delivery_location_source, :string
    add_column :trips, :delivery_location_resolved_at, :datetime

    add_index :trips, :delivery_place_id
    add_index :trips, [:delivery_lat, :delivery_lng]
  end
end

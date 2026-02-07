class ReplaceTruckTrailerWithVehicleOnTrips < ActiveRecord::Migration[8.0]
  def up
    add_reference :trips, :vehicle, foreign_key: true

    execute <<~SQL
      UPDATE trips
      SET vehicle_id = COALESCE(truck_id, trailer_id)
      WHERE vehicle_id IS NULL
    SQL

    remove_reference :trips, :truck, foreign_key: { to_table: :vehicles }
    remove_reference :trips, :trailer, foreign_key: { to_table: :vehicles }
  end

  def down
    add_reference :trips, :truck, foreign_key: { to_table: :vehicles }
    add_reference :trips, :trailer, foreign_key: { to_table: :vehicles }

    execute <<~SQL
      UPDATE trips
      SET truck_id = vehicle_id
      WHERE truck_id IS NULL
    SQL

    remove_reference :trips, :vehicle, foreign_key: true
  end
end

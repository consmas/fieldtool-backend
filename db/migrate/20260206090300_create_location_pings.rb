class CreateLocationPings < ActiveRecord::Migration[8.0]
  def change
    create_table :location_pings do |t|
      t.references :trip, null: false, foreign_key: true
      t.decimal :lat, precision: 10, scale: 6, null: false
      t.decimal :lng, precision: 10, scale: 6, null: false
      t.decimal :speed, precision: 8, scale: 2
      t.decimal :heading, precision: 6, scale: 2
      t.datetime :recorded_at, null: false
      t.references :recorded_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :location_pings, [:trip_id, :recorded_at]
  end
end

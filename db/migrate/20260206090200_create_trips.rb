class CreateTrips < ActiveRecord::Migration[8.0]
  def change
    create_table :trips do |t|
      t.string :reference_code
      t.integer :status, null: false, default: 0

      t.references :driver, null: false, foreign_key: { to_table: :users }
      t.references :dispatcher, foreign_key: { to_table: :users }
      t.references :truck, foreign_key: { to_table: :vehicles }
      t.references :trailer, foreign_key: { to_table: :vehicles }

      t.string :pickup_location
      t.string :dropoff_location
      t.text :pickup_notes
      t.text :dropoff_notes
      t.string :material_description

      t.datetime :scheduled_pickup_at
      t.datetime :scheduled_dropoff_at

      t.decimal :start_odometer_km, precision: 10, scale: 1
      t.decimal :end_odometer_km, precision: 10, scale: 1
      t.datetime :start_odometer_captured_at
      t.datetime :end_odometer_captured_at
      t.references :start_odometer_captured_by, foreign_key: { to_table: :users }
      t.references :end_odometer_captured_by, foreign_key: { to_table: :users }
      t.text :start_odometer_note
      t.text :end_odometer_note
      t.decimal :start_odometer_lat, precision: 10, scale: 6
      t.decimal :start_odometer_lng, precision: 10, scale: 6
      t.decimal :end_odometer_lat, precision: 10, scale: 6
      t.decimal :end_odometer_lng, precision: 10, scale: 6

      t.datetime :status_changed_at
      t.datetime :completed_at
      t.datetime :cancelled_at

      t.timestamps
    end

    add_index :trips, :status
    add_index :trips, :reference_code
  end
end

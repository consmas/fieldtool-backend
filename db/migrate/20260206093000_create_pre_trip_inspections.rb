class CreatePreTripInspections < ActiveRecord::Migration[8.0]
  def change
    create_table :pre_trip_inspections do |t|
      t.references :trip, null: false, foreign_key: true, index: { unique: true }
      t.references :captured_by, null: false, foreign_key: { to_table: :users }

      t.decimal :odometer_value_km, precision: 10, scale: 1, null: false
      t.datetime :odometer_captured_at, null: false
      t.decimal :odometer_lat, precision: 10, scale: 6
      t.decimal :odometer_lng, precision: 10, scale: 6

      t.boolean :brakes, null: false
      t.boolean :tyres, null: false
      t.boolean :lights, null: false
      t.boolean :mirrors, null: false
      t.boolean :horn, null: false
      t.boolean :fuel_sufficient, null: false
      t.boolean :load_area_ready, null: false

      t.integer :load_status, null: false, default: 0
      t.boolean :load_secured, null: false
      t.text :load_note

      t.boolean :accepted, null: false
      t.datetime :accepted_at

      t.string :waybill_number
      t.string :assistant_name
      t.string :assistant_phone
      t.string :fuel_level

      t.timestamps
    end

    add_index :pre_trip_inspections, :load_status
  end
end

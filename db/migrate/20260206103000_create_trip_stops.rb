class CreateTripStops < ActiveRecord::Migration[8.0]
  def change
    create_table :trip_stops do |t|
      t.references :trip, null: false, foreign_key: true
      t.integer :sequence, null: false
      t.string :destination
      t.string :delivery_address
      t.string :tonnage_load
      t.string :waybill_number
      t.string :customer_contact_name
      t.string :customer_contact_phone
      t.text :special_instructions
      t.time :arrival_time_at_site
      t.integer :pod_type, null: false, default: 0
      t.boolean :waybill_returned
      t.text :notes_incidents

      t.timestamps
    end

    add_index :trip_stops, [:trip_id, :sequence], unique: true
    add_index :trip_stops, :pod_type
  end
end

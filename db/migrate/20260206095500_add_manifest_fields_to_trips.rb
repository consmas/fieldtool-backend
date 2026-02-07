class AddManifestFieldsToTrips < ActiveRecord::Migration[8.0]
  def change
    change_table :trips, bulk: true do |t|
      # Section A: General Trip Information
      t.date :trip_date
      t.string :truck_reg_no
      t.string :driver_contact
      t.string :truck_type_capacity
      t.decimal :road_expense_disbursed, precision: 10, scale: 2
      t.string :road_expense_reference

      # Section B: Delivery Details
      t.string :client_name
      t.string :destination
      t.string :delivery_address
      t.string :tonnage_load
      t.time :estimated_departure_time
      t.time :estimated_arrival_time
      t.string :customer_contact_name
      t.string :customer_contact_phone
      t.text :special_instructions

      # Section C: Delivery Completion & Return
      t.time :arrival_time_at_site
      t.integer :pod_type, null: false, default: 0
      t.boolean :waybill_returned
      t.text :notes_incidents

      # Section D: Fuel Refilling
      t.string :fuel_station_used
      t.integer :fuel_payment_mode, null: false, default: 0
      t.decimal :fuel_litres_filled, precision: 10, scale: 2
      t.string :fuel_receipt_no

      # Section E: Post-Trip
      t.time :return_time
      t.integer :vehicle_condition_post_trip, null: false, default: 0
      t.string :post_trip_inspector_name
    end
  end
end

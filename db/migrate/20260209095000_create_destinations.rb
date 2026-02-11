class CreateDestinations < ActiveRecord::Migration[8.0]
  def change
    create_table :destinations do |t|
      t.string :name, null: false
      t.decimal :average_distance_km, precision: 10, scale: 2, null: false, default: 0
      t.decimal :base_price_per_ton, precision: 10, scale: 2, null: false, default: 0
      t.decimal :tons_per_trip, precision: 10, scale: 2, null: false, default: 0
      t.decimal :kms_per_liter, precision: 10, scale: 2, null: false, default: 3.0
      t.decimal :fuel_price_ref, precision: 10, scale: 2, null: false, default: 0
      t.decimal :additional_provision_pct, precision: 5, scale: 2, null: false, default: 0.25
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :destinations, :name, unique: true
    add_index :destinations, :active
  end
end

class AddRateFieldsToDestinations < ActiveRecord::Migration[8.0]
  def change
    add_column :destinations, :base_km, :decimal, precision: 10, scale: 2, null: false, default: 100
    add_column :destinations, :base_trip_cost, :decimal, precision: 12, scale: 2, null: false, default: 0
    add_column :destinations, :liters_per_km, :decimal, precision: 10, scale: 2, null: false, default: 1.0
  end
end

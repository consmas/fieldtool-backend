class CreateFuelPrices < ActiveRecord::Migration[8.0]
  def change
    create_table :fuel_prices do |t|
      t.decimal :price_per_liter, precision: 10, scale: 2, null: false
      t.datetime :effective_at, null: false
      t.bigint :updated_by_id

      t.timestamps
    end

    add_index :fuel_prices, :effective_at
    add_index :fuel_prices, :updated_by_id
  end
end

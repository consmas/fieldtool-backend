class CreateVehicles < ActiveRecord::Migration[8.0]
  def change
    create_table :vehicles do |t|
      t.string :name, null: false
      t.integer :kind, null: false, default: 0
      t.string :license_plate
      t.string :vin
      t.text :notes
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :vehicles, :kind
    add_index :vehicles, :license_plate
    add_index :vehicles, :active
  end
end

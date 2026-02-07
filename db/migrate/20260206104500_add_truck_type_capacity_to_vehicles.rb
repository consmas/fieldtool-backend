class AddTruckTypeCapacityToVehicles < ActiveRecord::Migration[8.0]
  def change
    add_column :vehicles, :truck_type_capacity, :string
  end
end

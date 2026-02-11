class AddLogisticsFieldsToTrips < ActiveRecord::Migration[8.0]
  def change
    add_column :trips, :fuel_allocated_litres, :decimal, precision: 10, scale: 2
    add_column :trips, :fuel_allocation_station, :string
    add_column :trips, :fuel_allocation_payment_mode, :integer
    add_column :trips, :fuel_allocation_reference, :string
    add_column :trips, :fuel_allocated_by_id, :bigint
    add_column :trips, :fuel_allocated_at, :datetime
    add_column :trips, :fuel_allocation_note, :text

    add_column :trips, :road_expense_payment_status, :integer, default: 0, null: false
    add_column :trips, :road_expense_paid_at, :datetime
    add_column :trips, :road_expense_paid_by_id, :bigint
    add_column :trips, :road_expense_payment_method, :integer
    add_column :trips, :road_expense_payment_reference, :string
    add_column :trips, :road_expense_note, :text

    add_index :trips, :fuel_allocated_by_id
    add_index :trips, :road_expense_paid_by_id
    add_index :trips, :road_expense_payment_status
  end
end

class AddWaybillToTrips < ActiveRecord::Migration[8.0]
  def change
    add_column :trips, :waybill_number, :string
    add_index :trips, :waybill_number
  end
end

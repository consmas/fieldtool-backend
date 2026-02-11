class AddLogisticsFieldsToPreTripInspections < ActiveRecord::Migration[8.0]
  def change
    add_column :pre_trip_inspections, :inspection_verification_status, :integer, default: 0, null: false
    add_column :pre_trip_inspections, :inspection_verified_by_id, :bigint
    add_column :pre_trip_inspections, :inspection_verified_at, :datetime
    add_column :pre_trip_inspections, :inspection_verification_note, :text
    add_column :pre_trip_inspections, :inspection_confirmed, :boolean, default: false, null: false
    add_column :pre_trip_inspections, :inspection_confirmed_by_id, :bigint
    add_column :pre_trip_inspections, :inspection_confirmed_at, :datetime

    add_index :pre_trip_inspections, :inspection_verification_status
    add_index :pre_trip_inspections, :inspection_verified_by_id
    add_index :pre_trip_inspections, :inspection_confirmed_by_id
  end
end

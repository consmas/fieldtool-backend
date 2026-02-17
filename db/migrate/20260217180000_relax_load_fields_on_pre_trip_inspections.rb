class RelaxLoadFieldsOnPreTripInspections < ActiveRecord::Migration[8.0]
  def change
    change_column_null :pre_trip_inspections, :load_area_ready, true
    change_column_null :pre_trip_inspections, :load_secured, true
    change_column_null :pre_trip_inspections, :load_status, true
    change_column_default :pre_trip_inspections, :load_status, from: 0, to: nil
  end
end

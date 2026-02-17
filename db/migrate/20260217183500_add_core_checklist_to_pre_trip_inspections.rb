class AddCoreChecklistToPreTripInspections < ActiveRecord::Migration[8.0]
  def change
    add_column :pre_trip_inspections, :core_checklist, :jsonb, default: {}, null: false
  end
end

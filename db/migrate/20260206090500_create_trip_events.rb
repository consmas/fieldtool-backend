class CreateTripEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :trip_events do |t|
      t.references :trip, null: false, foreign_key: true
      t.string :event_type, null: false
      t.string :message
      t.jsonb :data, null: false, default: {}
      t.references :created_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :trip_events, :event_type
    add_index :trip_events, [:trip_id, :created_at]
  end
end

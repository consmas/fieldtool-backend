class CreateEvidence < ActiveRecord::Migration[8.0]
  def change
    create_table :evidence do |t|
      t.references :trip, null: false, foreign_key: true
      t.integer :kind, null: false, default: 0
      t.text :note
      t.decimal :lat, precision: 10, scale: 6
      t.decimal :lng, precision: 10, scale: 6
      t.datetime :recorded_at, null: false
      t.references :uploaded_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :evidence, :kind
    add_index :evidence, [:trip_id, :recorded_at]
  end
end

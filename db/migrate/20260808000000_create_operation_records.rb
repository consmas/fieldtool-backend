class CreateOperationRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :operation_records do |t|
      t.string :record_type, null: false, default: "trip"
      t.date :entry_date
      t.string :reporting_month
      t.string :trip_id
      t.string :waybill_no
      t.string :truck_id
      t.string :driver_name
      t.string :cargo_type
      t.string :origin
      t.string :destination
      t.decimal :expected_revenue, precision: 12, scale: 2, default: 0
      t.string :status
      t.text :notes
      t.jsonb :details, default: {}, null: false
      t.string :source_file_name
      t.timestamps
    end

    add_index :operation_records, :record_type
    add_index :operation_records, :entry_date
    add_index :operation_records, :truck_id
    add_index :operation_records, :driver_name
    add_index :operation_records, :created_at
  end
end

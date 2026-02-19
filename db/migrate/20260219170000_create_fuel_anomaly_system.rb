class CreateFuelAnomalySystem < ActiveRecord::Migration[8.0]
  def change
    create_table :fuel_logs do |t|
      t.references :vehicle, null: false, foreign_key: true
      t.references :trip, null: true, foreign_key: true
      t.references :driver, null: true, foreign_key: { to_table: :users }
      t.string :transaction_type, null: false
      t.string :fuel_type, null: false, default: "diesel"
      t.decimal :liters, precision: 12, scale: 3, null: false
      t.decimal :cost_per_liter, precision: 12, scale: 3, null: false, default: 0
      t.decimal :total_cost, precision: 12, scale: 2, null: false, default: 0
      t.integer :odometer_reading
      t.string :station_name
      t.string :station_location
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.string :fuel_card_reference
      t.string :receipt_number
      t.boolean :is_full_tank, null: false, default: false
      t.datetime :fueled_at, null: false
      t.references :recorded_by, null: true, foreign_key: { to_table: :users }
      t.text :notes
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end
    add_index :fuel_logs, :fueled_at
    add_index :fuel_logs, :transaction_type

    create_table :fuel_analysis_records do |t|
      t.references :vehicle, null: false, foreign_key: true
      t.references :trip, null: true, foreign_key: true
      t.references :driver, null: true, foreign_key: { to_table: :users }
      t.string :analysis_type, null: false
      t.decimal :distance_km, precision: 12, scale: 3, null: false, default: 0
      t.decimal :fuel_consumed_liters, precision: 12, scale: 3, null: false, default: 0
      t.decimal :expected_consumption_liters, precision: 12, scale: 3, null: false, default: 0
      t.decimal :actual_km_per_liter, precision: 12, scale: 4
      t.decimal :expected_km_per_liter, precision: 12, scale: 4
      t.decimal :variance_percent, precision: 8, scale: 2, null: false, default: 0
      t.decimal :variance_liters, precision: 12, scale: 3, null: false, default: 0
      t.decimal :anomaly_score, precision: 6, scale: 2, null: false, default: 0
      t.boolean :is_anomaly, null: false, default: false
      t.string :anomaly_type
      t.string :anomaly_severity
      t.string :possible_causes, null: false, default: [], array: true
      t.string :investigation_status
      t.text :investigation_notes
      t.references :investigated_by, null: true, foreign_key: { to_table: :users }
      t.datetime :period_start
      t.datetime :period_end

      t.timestamps
    end
    add_index :fuel_analysis_records, :is_anomaly
    add_index :fuel_analysis_records, :anomaly_severity
    add_index :fuel_analysis_records, :investigation_status

    add_column :vehicles, :fuel_type, :string, default: "diesel" unless column_exists?(:vehicles, :fuel_type)
    add_column :vehicles, :tank_capacity_liters, :decimal, precision: 12, scale: 3 unless column_exists?(:vehicles, :tank_capacity_liters)
    add_column :vehicles, :baseline_km_per_liter, :decimal, precision: 12, scale: 4 unless column_exists?(:vehicles, :baseline_km_per_liter)
    add_column :vehicles, :anomaly_threshold_percent, :decimal, precision: 8, scale: 2, default: 20.0 unless column_exists?(:vehicles, :anomaly_threshold_percent)
    add_column :vehicles, :average_km_per_liter, :decimal, precision: 12, scale: 4 unless column_exists?(:vehicles, :average_km_per_liter)
    add_column :vehicles, :total_fuel_consumed_liters, :decimal, precision: 14, scale: 3, default: 0 unless column_exists?(:vehicles, :total_fuel_consumed_liters)
    add_column :vehicles, :total_fuel_cost, :decimal, precision: 14, scale: 2, default: 0 unless column_exists?(:vehicles, :total_fuel_cost)
  end
end

class CreateMaintenanceAndWorkOrderSystem < ActiveRecord::Migration[8.0]
  def change
    create_table :maintenance_vendors do |t|
      t.string :name, null: false
      t.string :contact_name
      t.string :phone
      t.string :email
      t.text :address
      t.string :city
      t.string :specializations, array: true, default: [], null: false
      t.decimal :rating, precision: 3, scale: 2
      t.boolean :is_active, null: false, default: true
      t.text :notes
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end
    add_index :maintenance_vendors, :is_active
    add_index :maintenance_vendors, :city
    add_index :maintenance_vendors, :specializations, using: :gin

    create_table :maintenance_schedules do |t|
      t.references :vehicle, null: true, foreign_key: true
      t.string :vehicle_type
      t.string :name, null: false
      t.text :description
      t.string :schedule_type, null: false
      t.integer :mileage_interval_km
      t.integer :time_interval_days
      t.datetime :last_performed_at
      t.integer :last_performed_km
      t.datetime :next_due_at
      t.integer :next_due_km
      t.string :priority, null: false, default: "medium"
      t.boolean :is_active, null: false, default: true
      t.integer :notify_before_km, null: false, default: 0
      t.integer :notify_before_days, null: false, default: 0
      t.decimal :estimated_duration_hrs, precision: 6, scale: 2
      t.decimal :estimated_cost, precision: 12, scale: 2
      t.references :created_by, null: true, foreign_key: { to_table: :users }

      t.timestamps
    end
    add_index :maintenance_schedules, :vehicle_type
    add_index :maintenance_schedules, :is_active
    add_index :maintenance_schedules, :next_due_km
    add_index :maintenance_schedules, :next_due_at
    add_index :maintenance_schedules, :priority

    create_table :work_orders do |t|
      t.string :work_order_number, null: false
      t.references :vehicle, null: false, foreign_key: true
      t.references :maintenance_schedule, null: true, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.string :work_order_type, null: false, default: "preventive"
      t.string :status, null: false, default: "draft"
      t.string :priority, null: false, default: "medium"
      t.string :assigned_to
      t.string :assigned_to_type
      t.references :vendor, null: true, foreign_key: { to_table: :maintenance_vendors }
      t.references :reported_by, null: true, foreign_key: { to_table: :users }
      t.datetime :reported_at
      t.date :scheduled_date
      t.datetime :started_at
      t.datetime :completed_at
      t.integer :odometer_at_creation
      t.decimal :estimated_cost, precision: 12, scale: 2
      t.decimal :actual_cost, precision: 12, scale: 2
      t.decimal :labor_hours, precision: 8, scale: 2
      t.decimal :labor_cost, precision: 12, scale: 2
      t.decimal :parts_cost, precision: 12, scale: 2
      t.text :notes
      t.text :resolution_notes
      t.string :failure_reason
      t.decimal :downtime_hours, precision: 8, scale: 2
      t.jsonb :metadata, null: false, default: {}
      t.references :expense_entry, null: true, foreign_key: true

      t.timestamps
    end
    add_index :work_orders, :work_order_number, unique: true
    add_index :work_orders, :status
    add_index :work_orders, :work_order_type
    add_index :work_orders, :priority
    add_index :work_orders, :scheduled_date

    create_table :work_order_parts do |t|
      t.references :work_order, null: false, foreign_key: true
      t.string :part_name, null: false
      t.string :part_number
      t.decimal :quantity, precision: 12, scale: 3, null: false, default: 1
      t.string :unit
      t.decimal :unit_cost, precision: 12, scale: 2, null: false, default: 0
      t.decimal :total_cost, precision: 12, scale: 2, null: false, default: 0
      t.string :supplier
      t.string :notes

      t.timestamps
    end

    create_table :work_order_comments do |t|
      t.references :work_order, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :comment, null: false
      t.string :comment_type, null: false, default: "note"
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end
    add_index :work_order_comments, :comment_type

    create_table :vehicle_documents do |t|
      t.references :vehicle, null: false, foreign_key: true
      t.string :document_type, null: false
      t.string :document_number
      t.date :issued_at
      t.date :expires_at
      t.string :issuing_authority
      t.decimal :cost, precision: 12, scale: 2
      t.string :status, null: false, default: "active"
      t.integer :notify_before_days, null: false, default: 30
      t.text :notes
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end
    add_index :vehicle_documents, :document_type
    add_index :vehicle_documents, :status
    add_index :vehicle_documents, :expires_at
  end
end

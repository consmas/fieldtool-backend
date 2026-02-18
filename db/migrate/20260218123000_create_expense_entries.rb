class CreateExpenseEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :expense_entries do |t|
      t.references :trip, foreign_key: true
      t.references :vehicle, foreign_key: true
      t.references :driver, foreign_key: { to_table: :users }

      t.integer :category, null: false
      t.string :subcategory
      t.text :description
      t.decimal :quantity, precision: 12, scale: 3
      t.decimal :unit_cost, precision: 12, scale: 3
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string :currency, null: false, default: "GHS"

      t.integer :status, null: false, default: 0
      t.datetime :expense_date, null: false
      t.string :payment_method
      t.string :reference
      t.string :vendor_name
      t.string :receipt_url

      t.boolean :is_auto_generated, null: false, default: false
      t.string :auto_rule_key
      t.jsonb :metadata, null: false, default: {}

      t.references :created_by, foreign_key: { to_table: :users }
      t.references :approved_by, foreign_key: { to_table: :users }
      t.references :paid_by, foreign_key: { to_table: :users }
      t.datetime :approved_at
      t.datetime :paid_at
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :expense_entries, :category
    add_index :expense_entries, :status
    add_index :expense_entries, :expense_date
    add_index :expense_entries, [:is_auto_generated, :auto_rule_key]
    add_index :expense_entries, :deleted_at
    add_index :expense_entries, [:trip_id, :category, :auto_rule_key, :deleted_at], name: "index_expense_entries_on_trip_category_rule"
  end
end

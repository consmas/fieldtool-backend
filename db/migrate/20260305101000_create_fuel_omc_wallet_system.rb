class CreateFuelOmcWalletSystem < ActiveRecord::Migration[8.0]
  def change
    create_table :fuel_deposits do |t|
      t.string :omc_name, null: false
      t.decimal :amount, precision: 14, scale: 2, null: false
      t.string :currency, null: false, default: "GHS"
      t.datetime :deposit_date, null: false
      t.string :payment_method, null: false, default: "bank_transfer"
      t.string :reference_no
      t.string :status, null: false, default: "confirmed"
      t.text :notes
      t.bigint :created_by_id, null: false
      t.bigint :confirmed_by_id
      t.datetime :confirmed_at
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :fuel_deposits, :omc_name
    add_index :fuel_deposits, :deposit_date
    add_index :fuel_deposits, :status
    add_index :fuel_deposits, :reference_no
    add_foreign_key :fuel_deposits, :users, column: :created_by_id
    add_foreign_key :fuel_deposits, :users, column: :confirmed_by_id

    create_table :fuel_omc_balances do |t|
      t.string :omc_name, null: false
      t.decimal :balance, precision: 14, scale: 2, null: false, default: 0
      t.string :currency, null: false, default: "GHS"
      t.timestamps
    end

    add_index :fuel_omc_balances, :omc_name, unique: true

    create_table :fuel_omc_ledger_entries do |t|
      t.references :fuel_omc_balance, null: false, foreign_key: true, index: { name: "index_fuel_ledger_entries_on_balance_id" }
      t.string :entry_type, null: false
      t.decimal :amount, precision: 14, scale: 2, null: false
      t.decimal :balance_before, precision: 14, scale: 2, null: false
      t.decimal :balance_after, precision: 14, scale: 2, null: false
      t.string :reference_type
      t.bigint :reference_id
      t.bigint :actor_id
      t.text :note
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :fuel_omc_ledger_entries, [:reference_type, :reference_id], name: "index_fuel_ledger_entries_on_reference"
    add_index :fuel_omc_ledger_entries, :entry_type
    add_foreign_key :fuel_omc_ledger_entries, :users, column: :actor_id

    change_table :fuel_logs, bulk: true do |t|
      t.string :omc_name
      t.string :funding_source, null: false, default: "cash"
      t.boolean :deducted_from_omc, null: false, default: false
    end

    add_index :fuel_logs, :omc_name
    add_index :fuel_logs, :funding_source
  end
end

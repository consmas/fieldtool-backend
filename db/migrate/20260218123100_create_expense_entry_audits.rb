class CreateExpenseEntryAudits < ActiveRecord::Migration[8.0]
  def change
    create_table :expense_entry_audits do |t|
      t.references :expense_entry, null: false, foreign_key: true
      t.references :actor, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.string :from_status
      t.string :to_status
      t.text :reason
      t.jsonb :changeset, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :expense_entry_audits, :action
    add_index :expense_entry_audits, :created_at
  end
end

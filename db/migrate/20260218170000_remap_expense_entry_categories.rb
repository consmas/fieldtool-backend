class RemapExpenseEntryCategories < ActiveRecord::Migration[8.0]
  def up
    # Old mapping:
    # 0=fuel, 1=road_fee, 2=salary, 3=purchase, 4=tires, 5=maintenance, 6=repair, 7=emergency, 8=other
    # New mapping:
    # 0=insurance, 1=registration_licensing, 2=taxes_levies, 3=road_expenses, 4=fuel,
    # 5=repairs_maintenance, 6=fleet_staff_costs, 7=bank_charges, 8=other_overheads
    execute <<~SQL.squish
      UPDATE expense_entries
      SET category = CASE category
        WHEN 0 THEN 4
        WHEN 1 THEN 3
        WHEN 2 THEN 6
        WHEN 3 THEN 8
        WHEN 4 THEN 5
        WHEN 5 THEN 5
        WHEN 6 THEN 5
        WHEN 7 THEN 8
        WHEN 8 THEN 8
        ELSE category
      END
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Cannot reliably restore old expense categories."
  end
end

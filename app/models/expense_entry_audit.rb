class ExpenseEntryAudit < ApplicationRecord
  belongs_to :expense_entry
  belongs_to :actor, class_name: "User", optional: true

  validates :action, presence: true
end

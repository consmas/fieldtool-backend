module Expenses
  class AuditLogger
    def self.log!(expense_entry:, actor:, action:, from_status: nil, to_status: nil, reason: nil, changeset: {}, metadata: {})
      ExpenseEntryAudit.create!(
        expense_entry: expense_entry,
        actor: actor,
        action: action,
        from_status: from_status,
        to_status: to_status,
        reason: reason,
        changeset: changeset || {},
        metadata: metadata || {}
      )
    end
  end
end

module Expenses
  class ExpenseApprovalNotifyJob < ApplicationJob
    queue_as :default

    def perform(expense_id, action)
      expense = ExpenseEntry.find_by(id: expense_id)
      return if expense.nil?

      notification_type = action.to_s == "approved" ? "expense.approved" : "expense.rejected"
      NotificationService.notify(
        notification_type: notification_type,
        recipients: [expense.created_by_id].compact,
        notifiable: expense,
        data: {
          amount: expense.amount.to_d,
          category: expense.category,
          reason: expense.metadata&.dig("rejection_reason")
        }
      )
    end
  end
end

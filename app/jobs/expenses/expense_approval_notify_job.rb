module Expenses
  class ExpenseApprovalNotifyJob < ApplicationJob
    queue_as :default

    def perform(expense_id, action)
      expense = ExpenseEntry.find_by(id: expense_id)
      return if expense.nil?

      Notifications::InAppNotificationJob.perform_later(
        recipient_user_id: expense.created_by_id,
        kind: "expense_#{action}",
        payload: { expense_id: expense.id, status: expense.status, action: action }
      )
    end
  end
end

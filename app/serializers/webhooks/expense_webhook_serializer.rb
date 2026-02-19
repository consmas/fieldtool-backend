module Webhooks
  class ExpenseWebhookSerializer
    def initialize(expense)
      @expense = expense
    end

    def as_json(*)
      {
        id: @expense.id,
        trip_id: @expense.trip_id,
        vehicle_id: @expense.vehicle_id,
        driver_id: @expense.driver_id,
        category: @expense.category,
        status: @expense.status,
        amount: @expense.amount,
        currency: @expense.currency,
        expense_date: @expense.expense_date,
        reference: @expense.reference,
        description: @expense.description
      }
    end
  end
end

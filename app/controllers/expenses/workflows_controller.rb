class Expenses::WorkflowsController < ApplicationController
  rescue_from ArgumentError do |error|
    render json: { error: [error.message] }, status: :unprocessable_entity
  end

  def submit
    expense = find_expense
    authorize expense, :submit?
    from_status = expense.status
    expense.submit!
    audit(expense, "submitted", from_status, expense.status)
    render json: { id: expense.id, status: expense.status }
  end

  def approve
    expense = find_expense
    authorize expense, :approve?
    from_status = expense.status
    expense.approve!(by_user: current_user)
    audit(expense, "approved", from_status, expense.status)
    render json: { id: expense.id, status: expense.status, approved_at: expense.approved_at }
  end

  def reject
    expense = find_expense
    authorize expense, :reject?
    reason = params[:reason].presence || params.dig(:workflow, :reason).presence
    return render json: { error: ["reason is required"] }, status: :unprocessable_entity if reason.blank?

    from_status = expense.status
    expense.reject!(reason: reason)
    audit(expense, "rejected", from_status, expense.status, reason:)
    render json: { id: expense.id, status: expense.status }
  end

  def mark_paid
    expense = find_expense
    authorize expense, :mark_paid?
    from_status = expense.status
    expense.mark_paid!(by_user: current_user)
    audit(expense, "marked_paid", from_status, expense.status)
    render json: { id: expense.id, status: expense.status, paid_at: expense.paid_at }
  end

  private

  def find_expense
    ExpenseEntry.active.find(params[:id])
  end

  def audit(expense, action, from_status, to_status, reason: nil)
    Expenses::AuditLogger.log!(
      expense_entry: expense,
      actor: current_user,
      action: action,
      from_status: from_status,
      to_status: to_status,
      reason: reason
    )
  end
end

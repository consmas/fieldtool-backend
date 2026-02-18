class Expenses::BulkController < ApplicationController
  def approve
    authorize ExpenseEntry, :bulk_workflow?
    process_bulk(:approve!)
  end

  def reject
    authorize ExpenseEntry, :bulk_workflow?
    reason = params[:reason].presence || params.dig(:bulk, :reason).presence
    return render json: { error: ["reason is required"] }, status: :unprocessable_entity if reason.blank?

    process_bulk(:reject!, reason:)
  end

  def mark_paid
    authorize ExpenseEntry, :bulk_workflow?
    process_bulk(:mark_paid!, by_user: current_user)
  end

  private

  def process_bulk(method_name, **kwargs)
    ids = expense_ids
    expenses = ExpenseEntry.active.where(id: ids)
    updated_ids = []
    failures = []

    expenses.find_each do |expense|
      from_status = expense.status
      if method_name == :approve!
        expense.approve!(by_user: current_user)
      elsif method_name == :reject!
        expense.reject!(reason: kwargs[:reason])
      else
        expense.mark_paid!(by_user: current_user)
      end

      Expenses::AuditLogger.log!(
        expense_entry: expense,
        actor: current_user,
        action: "bulk_#{method_name.to_s.delete('!')}",
        from_status: from_status,
        to_status: expense.status,
        reason: kwargs[:reason]
      )
      updated_ids << expense.id
    rescue StandardError => e
      failures << { id: expense.id, error: e.message }
    end

    render json: { updated_ids:, failures: }
  end

  def expense_ids
    ids = params[:ids] || params.dig(:bulk, :ids)
    Array(ids).map(&:to_i).uniq
  end
end

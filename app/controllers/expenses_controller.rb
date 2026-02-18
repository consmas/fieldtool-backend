class ExpensesController < ApplicationController
  def index
    authorize ExpenseEntry
    expenses = apply_filters(policy_scope(ExpenseEntry)).order(created_at: :desc)
    expenses = expenses.limit(limit_param).offset(offset_param)
    render json: expenses.map { |expense| expense_payload(expense) }
  end

  def create
    expense = ExpenseEntry.new(expense_params)
    authorize expense
    expense.created_by ||= current_user
    expense.save!

    Expenses::AuditLogger.log!(
      expense_entry: expense,
      actor: current_user,
      action: "created",
      to_status: expense.status,
      changeset: expense.attributes
    )

    render json: expense_payload(expense), status: :created
  end

  def update
    expense = ExpenseEntry.active.find(params[:id])
    authorize expense
    if !finance_or_admin_current_user? && !expense.status_draft?
      return render json: { error: ["Only draft expenses can be edited"] }, status: :unprocessable_entity
    end

    old_attributes = expense.attributes.slice(*expense_params.keys.map(&:to_s))
    old_status = expense.status
    expense.update!(expense_params)

    Expenses::AuditLogger.log!(
      expense_entry: expense,
      actor: current_user,
      action: "updated",
      from_status: old_status,
      to_status: expense.status,
      changeset: { before: old_attributes, after: expense.attributes.slice(*old_attributes.keys) }
    )

    render json: expense_payload(expense)
  end

  def destroy
    expense = ExpenseEntry.active.find(params[:id])
    authorize expense
    expense.soft_delete!

    Expenses::AuditLogger.log!(
      expense_entry: expense,
      actor: current_user,
      action: "soft_deleted",
      from_status: expense.status,
      to_status: expense.status
    )

    head :no_content
  end

  def summary
    authorize ExpenseEntry, :summary?
    scope = apply_filters(policy_scope(ExpenseEntry))

    render json: {
      total_expense: scope.sum(:amount).to_d,
      insurance_total: scope.where(category: :insurance).sum(:amount).to_d,
      registration_licensing_total: scope.where(category: :registration_licensing).sum(:amount).to_d,
      taxes_levies_total: scope.where(category: :taxes_levies).sum(:amount).to_d,
      road_expenses_total: scope.where(category: :road_expenses).sum(:amount).to_d,
      fuel_total: scope.where(category: :fuel).sum(:amount).to_d,
      repairs_maintenance_total: scope.where(category: :repairs_maintenance).sum(:amount).to_d,
      fleet_staff_costs_total: scope.where(category: :fleet_staff_costs).sum(:amount).to_d,
      bank_charges_total: scope.where(category: :bank_charges).sum(:amount).to_d,
      other_overheads_total: scope.where(category: :other_overheads).sum(:amount).to_d,
      pending_total: scope.where(status: :pending).sum(:amount).to_d,
      approved_total: scope.where(status: :approved).sum(:amount).to_d,
      paid_total: scope.where(status: :paid).sum(:amount).to_d,
      by_category: scope.group(:category).sum(:amount),
      by_status: scope.group(:status).sum(:amount),
      by_vehicle: scope.group(:vehicle_id).sum(:amount),
      by_driver: scope.group(:driver_id).sum(:amount),
      by_trip: scope.group(:trip_id).sum(:amount)
    }
  end

  private

  def expense_params
    params.require(:expense).permit(
      :trip_id,
      :vehicle_id,
      :driver_id,
      :category,
      :subcategory,
      :description,
      :quantity,
      :unit_cost,
      :amount,
      :currency,
      :status,
      :expense_date,
      :payment_method,
      :reference,
      :vendor_name,
      :receipt_url,
      :is_auto_generated,
      :auto_rule_key,
      :approved_by_id,
      :paid_by_id,
      :approved_at,
      :paid_at,
      metadata: {}
    )
  end

  def apply_filters(scope)
    scoped = scope.active
    scoped = scoped.where(category: params[:category]) if params[:category].present?
    scoped = scoped.where(status: params[:status]) if params[:status].present?
    scoped = scoped.where(trip_id: params[:trip_id]) if params[:trip_id].present?
    scoped = scoped.where(vehicle_id: params[:vehicle_id]) if params[:vehicle_id].present?
    scoped = scoped.where(driver_id: params[:driver_id]) if params[:driver_id].present?
    scoped = scoped.where("amount >= ?", params[:min_amount].to_d) if params[:min_amount].present?
    scoped = scoped.where("amount <= ?", params[:max_amount].to_d) if params[:max_amount].present?
    scoped = scoped.where(is_auto_generated: to_bool(params[:auto_generated])) if params[:auto_generated].present?
    scoped = scoped.where("expense_date >= ?", Time.zone.parse(params[:date_from])) if params[:date_from].present?
    scoped = scoped.where("expense_date <= ?", Time.zone.parse(params[:date_to])) if params[:date_to].present?
    scoped
  end

  def limit_param
    [params.fetch(:limit, 50).to_i, 200].min
  end

  def offset_param
    [params.fetch(:offset, 0).to_i, 0].max
  end

  def to_bool(value)
    ActiveModel::Type::Boolean.new.cast(value)
  end

  def expense_payload(expense)
    {
      id: expense.id,
      trip_id: expense.trip_id,
      vehicle_id: expense.vehicle_id,
      driver_id: expense.driver_id,
      category: expense.category,
      subcategory: expense.subcategory,
      description: expense.description,
      quantity: expense.quantity,
      unit_cost: expense.unit_cost,
      amount: expense.amount,
      currency: expense.currency,
      status: expense.status,
      expense_date: expense.expense_date,
      payment_method: expense.payment_method,
      reference: expense.reference,
      vendor_name: expense.vendor_name,
      receipt_url: expense.receipt_url,
      is_auto_generated: expense.is_auto_generated,
      auto_rule_key: expense.auto_rule_key,
      metadata: expense.metadata,
      created_by_id: expense.created_by_id,
      approved_by_id: expense.approved_by_id,
      paid_by_id: expense.paid_by_id,
      approved_at: expense.approved_at,
      paid_at: expense.paid_at,
      created_at: expense.created_at,
      updated_at: expense.updated_at
    }
  end

  def finance_or_admin_current_user?
    current_user&.finance? || current_user&.admin?
  end
end

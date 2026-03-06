class Fuel::DepositsController < ApplicationController
  include Rails.application.routes.url_helpers

  def index
    authorize FuelDeposit
    scope = policy_scope(FuelDeposit).order(deposit_date: :desc, created_at: :desc)
    scope = scope.where(omc_name: params[:omc_name]) if params[:omc_name].present?
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where("deposit_date >= ?", parse_time(params[:date_from])) if parse_time(params[:date_from]).present?
    scope = scope.where("deposit_date <= ?", parse_time(params[:date_to])) if parse_time(params[:date_to]).present?

    render json: { data: scope.map { |row| payload(row) } }
  end

  def show
    deposit = FuelDeposit.find(params[:id])
    authorize deposit

    render json: payload(deposit)
  end

  def create
    deposit = FuelDeposit.new(deposit_params)
    authorize deposit
    deposit.created_by_id = current_user.id
    deposit.status = "confirmed" if deposit.status.blank?

    FuelDeposit.transaction do
      deposit.save!
      attach_receipt!(deposit)
      mark_confirmed!(deposit) if deposit.status == "confirmed"
    end

    render json: payload(deposit), status: :created
  end

  def update
    deposit = FuelDeposit.find(params[:id])
    authorize deposit

    ensure_update_allowed!(deposit)

    FuelDeposit.transaction do
      was_confirmed = deposit.status == "confirmed"
      deposit.assign_attributes(deposit_params)
      deposit.save!
      attach_receipt!(deposit)
      mark_confirmed!(deposit) if !was_confirmed && deposit.status == "confirmed"
    end

    render json: payload(deposit)
  end

  def confirm
    deposit = FuelDeposit.find(params[:id])
    authorize deposit, :confirm?
    return render json: payload(deposit) if deposit.status == "confirmed"

    FuelDeposit.transaction do
      deposit.update!(status: "confirmed")
      mark_confirmed!(deposit)
    end

    render json: payload(deposit)
  end

  def balances
    authorize FuelDeposit, :balances?
    rows = FuelOmcBalance.order(:omc_name)
    render json: {
      data: rows.map do |row|
        {
          omc_name: row.omc_name,
          balance: row.balance,
          currency: row.currency,
          updated_at: row.updated_at
        }
      end
    }
  end

  def ledger
    authorize FuelDeposit, :ledger?
    scope = FuelOmcLedgerEntry.includes(:fuel_omc_balance, :actor).order(created_at: :desc)
    scope = scope.joins(:fuel_omc_balance).where(fuel_omc_balances: { omc_name: params[:omc_name] }) if params[:omc_name].present?
    scope = scope.where(entry_type: params[:entry_type]) if params[:entry_type].present?
    scope = scope.where("fuel_omc_ledger_entries.created_at >= ?", parse_time(params[:date_from])) if parse_time(params[:date_from]).present?
    scope = scope.where("fuel_omc_ledger_entries.created_at <= ?", parse_time(params[:date_to])) if parse_time(params[:date_to]).present?

    render json: {
      data: scope.limit(500).map do |row|
        {
          id: row.id,
          omc_name: row.fuel_omc_balance.omc_name,
          entry_type: row.entry_type,
          amount: row.amount,
          balance_before: row.balance_before,
          balance_after: row.balance_after,
          reference_type: row.reference_type,
          reference_id: row.reference_id,
          actor_id: row.actor_id,
          actor_name: row.actor&.name,
          note: row.note,
          created_at: row.created_at
        }
      end
    }
  end

  def reconcile
    authorize FuelDeposit, :reconcile?

    omc_name = params[:omc_name].presence || params.dig(:reconcile, :omc_name).presence
    month_value = params[:month].presence || params.dig(:reconcile, :month).presence
    statuses = Array(params[:target_statuses] || params.dig(:reconcile, :target_statuses)).map(&:to_s).presence || %w[approved paid]
    dry_run = ActiveModel::Type::Boolean.new.cast(params[:dry_run].presence || params.dig(:reconcile, :dry_run))

    return render json: { error: ["omc_name is required"] }, status: :unprocessable_entity if omc_name.blank?
    return render json: { error: ["month is required in YYYY-MM format"] }, status: :unprocessable_entity if month_value.blank?

    period_start = parse_month(month_value)
    return render json: { error: ["month must be in YYYY-MM format"] }, status: :unprocessable_entity if period_start.nil?

    period_end = period_start.end_of_month.end_of_day
    balance = FuelOmcBalance.find_or_create_by!(omc_name: omc_name) { |row| row.currency = "GHS"; row.balance = 0 }
    opening_balance = balance.balance.to_d

    scope = ExpenseEntry.active
      .where(category: ExpenseEntry.categories[:fuel])
      .where(status: statuses.map { |s| ExpenseEntry.statuses[s] }.compact)
      .where(expense_date: period_start..period_end)
      .order(:expense_date, :id)

    stats = {
      total: 0,
      eligible: 0,
      already_ledgered: 0,
      debited: 0,
      insufficient: 0
    }
    preview_rows = []
    current_balance = opening_balance

    work = lambda do
      scope.find_each do |expense|
        stats[:total] += 1
        if FuelOmcLedgerEntry.exists?(reference_type: "ExpenseEntry", reference_id: expense.id, entry_type: "debit")
          stats[:already_ledgered] += 1
          next
        end

        amount = expense.amount.to_d
        stats[:eligible] += 1
        if current_balance < amount
          stats[:insufficient] += 1
          preview_rows << { expense_id: expense.id, amount: amount.to_s("F"), status: "insufficient_balance" } if preview_rows.size < 100
          next
        end

        before = current_balance
        after = before - amount

        unless dry_run
          FuelOmcLedgerEntry.create!(
            fuel_omc_balance: balance,
            entry_type: "debit",
            amount: amount,
            balance_before: before,
            balance_after: after,
            reference_type: "ExpenseEntry",
            reference_id: expense.id,
            actor: current_user,
            note: "Fuel expense reconciliation debit",
            metadata: {
              omc_name: omc_name,
              month: period_start.strftime("%Y-%m"),
              expense_entry_id: expense.id
            }
          )
        end

        preview_rows << { expense_id: expense.id, amount: amount.to_s("F"), status: "debited" } if preview_rows.size < 100
        current_balance = after
        stats[:debited] += 1
      end
    end

    if dry_run
      work.call
    else
      FuelOmcBalance.transaction do
        balance.lock!
        current_balance = balance.balance.to_d
        work.call
        balance.update!(balance: current_balance)
      end
    end

    render json: {
      mode: dry_run ? "dry_run" : "apply",
      omc_name: omc_name,
      month: period_start.strftime("%Y-%m"),
      statuses: statuses,
      opening_balance: opening_balance.to_s("F"),
      closing_balance: current_balance.to_s("F"),
      stats: stats,
      preview: preview_rows
    }
  end

  private

  def deposit_params
    params.require(:fuel_deposit).permit(
      :omc_name,
      :amount,
      :currency,
      :deposit_date,
      :payment_method,
      :reference_no,
      :status,
      :notes,
      metadata: {}
    )
  end

  def attach_receipt!(deposit)
    receipt = params[:receipt] || params.dig(:fuel_deposit, :receipt)
    return if receipt.blank?

    deposit.receipt.attach(receipt)
  end

  def mark_confirmed!(deposit)
    return if deposit.confirmed_at.present?

    deposit.update!(confirmed_by_id: current_user.id, confirmed_at: Time.current)
    Fuel::OmcWalletService.credit_from_deposit!(deposit: deposit, actor: current_user)
  end

  def ensure_update_allowed!(deposit)
    return unless deposit.status == "confirmed"

    protected_attrs = %w[omc_name amount currency status deposit_date]
    attempted = deposit_params.to_h.keys.map(&:to_s)
    return if (attempted & protected_attrs).empty?

    deposit.errors.add(:base, "Confirmed deposits cannot change amount/omc/status/date")
    raise ActiveRecord::RecordInvalid, deposit
  end

  def payload(deposit)
    {
      id: deposit.id,
      omc_name: deposit.omc_name,
      amount: deposit.amount,
      currency: deposit.currency,
      deposit_date: deposit.deposit_date,
      payment_method: deposit.payment_method,
      reference_no: deposit.reference_no,
      status: deposit.status,
      notes: deposit.notes,
      created_by_id: deposit.created_by_id,
      confirmed_by_id: deposit.confirmed_by_id,
      confirmed_at: deposit.confirmed_at,
      metadata: deposit.metadata,
      receipt_attached: deposit.receipt.attached?,
      receipt_url: deposit.receipt.attached? ? rails_blob_url(deposit.receipt, only_path: true) : nil,
      created_at: deposit.created_at,
      updated_at: deposit.updated_at
    }
  end

  def parse_time(value)
    return nil if value.blank?

    Time.zone.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end

  def parse_month(value)
    Time.zone.strptime(value.to_s, "%Y-%m").beginning_of_month
  rescue ArgumentError, TypeError
    nil
  end
end

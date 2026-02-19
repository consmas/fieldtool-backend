class Api::V1::Client::InvoicesController < Api::V1::Client::BaseController
  def index
    scope = current_client.invoices
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where("issued_date >= ?", params[:date_from]) if params[:date_from].present?
    scope = scope.where("issued_date <= ?", params[:date_to]) if params[:date_to].present?

    render json: { data: scope.order(issued_date: :desc, created_at: :desc).map { |i| payload(i) } }
  end

  def show
    invoice = current_client.invoices.find_by!(invoice_number: params[:invoice_number])
    render json: payload(invoice, include_items: true)
  end

  def pdf
    invoice = current_client.invoices.find_by!(invoice_number: params[:invoice_number])
    render json: { invoice_number: invoice.invoice_number, message: "PDF generation not implemented yet" }, status: :not_implemented
  end

  def summary
    invoices = current_client.invoices
    render json: {
      total_billed: invoices.sum(:total_amount).to_d,
      total_paid: invoices.sum(:amount_paid).to_d,
      outstanding: invoices.sum(:balance_due).to_d,
      overdue: invoices.where(status: "overdue").sum(:balance_due).to_d,
      invoices_by_status: invoices.group(:status).count
    }
  end

  private

  def payload(invoice, include_items: false)
    data = {
      id: invoice.id,
      invoice_number: invoice.invoice_number,
      issued_date: invoice.issued_date,
      due_date: invoice.due_date,
      subtotal: invoice.subtotal,
      tax_rate: invoice.tax_rate,
      tax_amount: invoice.tax_amount,
      total_amount: invoice.total_amount,
      amount_paid: invoice.amount_paid,
      balance_due: invoice.balance_due,
      status: invoice.status,
      payment_terms: invoice.payment_terms,
      notes: invoice.notes
    }

    if include_items
      data[:line_items] = invoice.invoice_line_items.map do |item|
        {
          id: item.id,
          shipment_id: item.shipment_id,
          description: item.description,
          quantity: item.quantity,
          unit: item.unit,
          unit_price: item.unit_price,
          total: item.total
        }
      end
    end

    data
  end
end

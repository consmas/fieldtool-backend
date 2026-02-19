class Api::V1::ClientsController < ApplicationController
  before_action :set_client, only: [:show, :update, :shipments, :users, :create_user, :update_user, :create_invoice]

  def index
    authorize :webhook_admin, :show?

    render json: {
      data: Client.order(created_at: :desc).map do |client|
        {
          id: client.id,
          name: client.name,
          code: client.code,
          contact_email: client.contact_email,
          is_active: client.is_active,
          active_shipments_count: client.shipments.where(status: %w[confirmed picked_up in_transit arriving delivering]).count,
          total_revenue: client.invoices.sum(:total_amount).to_d,
          outstanding_balance: client.outstanding_balance.to_d
        }
      end
    }
  end

  def create
    authorize :webhook_admin, :show?

    client = Client.create!(client_params)
    render json: client_payload(client), status: :created
  end

  def show
    authorize :webhook_admin, :show?

    render json: client_payload(@client).merge(
      shipment_count: @client.shipments.count,
      invoices_count: @client.invoices.count
    )
  end

  def update
    authorize :webhook_admin, :show?

    @client.update!(client_params)
    render json: client_payload(@client)
  end

  def shipments
    authorize :webhook_admin, :show?

    render json: { data: @client.shipments.order(created_at: :desc).map { |s| { id: s.id, tracking_number: s.tracking_number, status: s.status, rate_amount: s.rate_amount } } }
  end

  def users
    authorize :webhook_admin, :show?

    render json: { data: @client.client_users.order(created_at: :desc).map { |u| { id: u.id, name: u.name, email: u.email, role: u.role, is_active: u.is_active } } }
  end

  def create_user
    authorize :webhook_admin, :show?

    password = SecureRandom.alphanumeric(12)
    user = @client.client_users.create!(
      email: params.require(:email),
      name: params.require(:name),
      role: params[:role] || "viewer",
      phone: params[:phone],
      password: password,
      password_confirmation: password
    )

    render json: { id: user.id, email: user.email, temp_password: password }, status: :created
  end

  def update_user
    authorize :webhook_admin, :show?

    user = @client.client_users.find(params[:user_id])
    user.update!(params.permit(:name, :phone, :role, :is_active))
    render json: { id: user.id, name: user.name, email: user.email, role: user.role, is_active: user.is_active }
  end

  def create_invoice
    authorize :webhook_admin, :show?

    shipment_ids = params.require(:shipment_ids)
    shipments = @client.shipments.where(id: shipment_ids)

    invoice = @client.invoices.create!(
      invoice_number: "INV-#{Time.current.year}-#{(@client.invoices.count + 1).to_s.rjust(5, '0')}",
      issued_date: Date.current,
      due_date: params[:due_date] || Date.current + 30.days,
      tax_rate: params[:tax_rate] || 0,
      payment_terms: params[:payment_terms] || @client.payment_terms,
      notes: params[:notes],
      status: "draft"
    )

    shipments.each do |shipment|
      invoice.invoice_line_items.create!(
        shipment_id: shipment.id,
        description: shipment.description.presence || shipment.tracking_number,
        quantity: 1,
        unit: shipment.rate_type || "trip",
        unit_price: shipment.rate_amount.to_d,
        total: shipment.rate_amount.to_d
      )
      shipment.update!(invoice_id: invoice.id)
    end

    invoice.recalculate_totals
    invoice.save!

    render json: { invoice_id: invoice.id, invoice_number: invoice.invoice_number, total_amount: invoice.total_amount }, status: :created
  end

  def send_invoice
    authorize :webhook_admin, :show?

    invoice = Invoice.find(params[:id])
    invoice.update!(status: "sent")
    render json: { id: invoice.id, status: invoice.status }
  end

  def record_payment
    authorize :webhook_admin, :show?

    invoice = Invoice.find(params[:id])
    amount = params.require(:amount).to_d
    invoice.amount_paid = invoice.amount_paid.to_d + amount
    invoice.recalculate_totals
    invoice.status = if invoice.balance_due <= 0
                       "paid"
                     elsif invoice.amount_paid.positive?
                       "partial"
                     else
                       invoice.status
                     end
    invoice.save!

    client = invoice.client
    client.update!(outstanding_balance: client.invoices.sum(:balance_due).to_d)

    render json: { id: invoice.id, amount_paid: invoice.amount_paid, balance_due: invoice.balance_due, status: invoice.status }
  end

  private

  def set_client
    @client = Client.find(params[:id])
  end

  def client_params
    params.require(:client).permit(
      :name,
      :code,
      :contact_name,
      :contact_email,
      :contact_phone,
      :billing_email,
      :address,
      :city,
      :region,
      :tax_id,
      :payment_terms,
      :contract_type,
      :rate_type,
      :default_rate,
      :credit_limit,
      :outstanding_balance,
      :is_active,
      :notes,
      metadata: {}
    )
  end

  def client_payload(client)
    {
      id: client.id,
      name: client.name,
      code: client.code,
      contact_name: client.contact_name,
      contact_email: client.contact_email,
      contact_phone: client.contact_phone,
      billing_email: client.billing_email,
      address: client.address,
      city: client.city,
      region: client.region,
      tax_id: client.tax_id,
      payment_terms: client.payment_terms,
      contract_type: client.contract_type,
      rate_type: client.rate_type,
      default_rate: client.default_rate,
      credit_limit: client.credit_limit,
      outstanding_balance: client.outstanding_balance,
      is_active: client.is_active,
      notes: client.notes
    }
  end
end

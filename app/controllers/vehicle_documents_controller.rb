class VehicleDocumentsController < ApplicationController
  def index
    vehicle = Vehicle.find(params[:vehicle_id])
    authorize VehicleDocument, :index?

    scope = vehicle.vehicle_documents
    scope = scope.where(document_type: params[:document_type]) if params[:document_type].present?
    scope = scope.where(status: params[:status]) if params[:status].present?

    render json: { data: scope.order(expires_at: :asc, created_at: :desc).map { |doc| document_payload(doc) } }
  end

  def create
    vehicle = Vehicle.find(params[:vehicle_id])
    authorize VehicleDocument, :create?

    doc = vehicle.vehicle_documents.new(document_params)
    doc.file.attach(params[:file]) if params[:file].present?
    doc.save!

    render json: document_payload(doc), status: :created
  end

  def update
    vehicle = Vehicle.find(params[:vehicle_id])
    doc = vehicle.vehicle_documents.find(params[:id])
    authorize doc, :update?

    doc.assign_attributes(document_params)
    doc.file.attach(params[:file]) if params[:file].present?
    doc.save!

    render json: document_payload(doc)
  end

  def expiring
    authorize VehicleDocument, :expiring?

    within_days = params[:days].presence&.to_i || 30
    docs = VehicleDocument.expiring_within(within_days).includes(:vehicle).order(expires_at: :asc)
    grouped = docs.group_by(&:vehicle_id)

    render json: {
      days: within_days,
      data: grouped.map do |vehicle_id, rows|
        vehicle = rows.first.vehicle
        {
          vehicle: { id: vehicle_id, name: vehicle.name, license_plate: vehicle.license_plate },
          documents: rows.map { |doc| document_payload(doc) }
        }
      end
    }
  end

  private

  def document_params
      params.require(:document).permit(:document_type, :document_number, :issued_at, :expires_at, :issuing_authority, :cost, :status, :notify_before_days, :notes, metadata: {})
    end

  def document_payload(doc)
    {
      id: doc.id,
      vehicle_id: doc.vehicle_id,
      document_type: doc.document_type,
      document_number: doc.document_number,
      issued_at: doc.issued_at,
      expires_at: doc.expires_at,
      issuing_authority: doc.issuing_authority,
      cost: doc.cost,
      status: doc.status,
      notify_before_days: doc.notify_before_days,
      days_until_expiry: doc.days_until_expiry,
      notes: doc.notes,
      metadata: doc.metadata,
      file_url: doc.file.attached? ? Rails.application.routes.url_helpers.rails_blob_url(doc.file, only_path: true) : nil,
      created_at: doc.created_at,
      updated_at: doc.updated_at
    }
  end
end

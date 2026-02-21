class DriverDocumentsController < ApplicationController
  before_action :set_profile
  skip_before_action :set_profile, only: [:expiring, :compliance_summary]

  def index
    authorize @profile, :show?, policy_class: DriverProfilePolicy

    scope = @profile.driver_documents
    scope = scope.where(document_type: params[:document_type]) if params[:document_type].present?
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(verification_status: params[:verification_status]) if params[:verification_status].present?

    render json: { data: scope.order(expires_at: :asc, created_at: :desc).map { |doc| payload(doc) } }
  end

  def create
    authorize @profile, :update?, policy_class: DriverProfilePolicy

    doc = @profile.driver_documents.new(document_params)
    doc.file.attach(params[:file]) if params[:file].present?
    doc.save!

    render json: payload(doc), status: :created
  end

  def update
    doc = @profile.driver_documents.find(params[:id])
    authorize doc, :update?

    doc.assign_attributes(document_params)
    doc.file.attach(params[:file]) if params[:file].present?
    doc.save!

    render json: payload(doc)
  end

  def verify
    doc = @profile.driver_documents.find(params[:id])
    authorize doc, :verify?

    status = params.require(:verification_status)
    doc.update!(
      verification_status: status,
      verified_by: current_user.id,
      verified_at: Time.current,
      notes: [doc.notes, params[:notes]].compact.join("\n")
    )

    render json: payload(doc)
  end

  def expiring
    authorize DriverDocument, :compliance?

    within_days = params[:days].presence&.to_i || 30
    docs = DriverDocument.where.not(expires_at: nil).where(expires_at: Date.current..(Date.current + within_days.days)).includes(driver_profile: :user)

    render json: {
      days: within_days,
      data: docs.group_by(&:driver_profile_id).map do |_profile_id, rows|
        profile = rows.first.driver_profile
        {
          driver: { user_id: profile.user_id, name: profile.user.name, email: profile.user.email },
          documents: rows.map { |doc| payload(doc) }
        }
      end
    }
  end

  def compliance_summary
    authorize DriverDocument, :compliance?

    total_drivers = DriverProfile.count
    fully_compliant = DriverProfile.left_joins(:driver_documents).group("driver_profiles.id").having("SUM(CASE WHEN driver_documents.status = 'expired' THEN 1 ELSE 0 END) = 0").count.size

    by_type = DriverDocument::DOCUMENT_TYPES.each_with_object({}) do |type, result|
      rows = DriverDocument.where(document_type: type)
      result[type] = {
        total: rows.count,
        active: rows.where(status: "active").count,
        expiring: rows.where(status: "expiring_soon").count,
        expired: rows.where(status: "expired").count
      }
    end

    render json: {
      total_drivers: total_drivers,
      fully_compliant: fully_compliant,
      documents_expiring_soon: DriverDocument.where(status: "expiring_soon").count,
      documents_expired: DriverDocument.where(status: "expired").count,
      unverified_documents: DriverDocument.where(verification_status: "unverified").count,
      by_document_type: by_type
    }
  end

  private

  def set_profile
    @profile = DriverProfile.find_by!(user_id: params[:driver_id])
  end

  def document_params
    params.require(:document).permit(
      :document_type,
      :document_number,
      :title,
      :issued_at,
      :expires_at,
      :issuing_authority,
      :status,
      :notify_before_days,
      :verification_status,
      :cost,
      :notes,
      metadata: {}
    )
  end

  def payload(doc)
    {
      id: doc.id,
      driver_profile_id: doc.driver_profile_id,
      document_type: doc.document_type,
      document_number: doc.document_number,
      title: doc.title,
      issued_at: doc.issued_at,
      expires_at: doc.expires_at,
      days_until_expiry: doc.days_until_expiry,
      issuing_authority: doc.issuing_authority,
      status: doc.status,
      notify_before_days: doc.notify_before_days,
      verification_status: doc.verification_status,
      verified_by: doc.verified_by,
      verified_at: doc.verified_at,
      cost: doc.cost,
      notes: doc.notes,
      file_url: doc.file.attached? ? Rails.application.routes.url_helpers.rails_blob_url(doc.file, only_path: true) : nil
    }
  end
end

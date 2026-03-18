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
    file = params[:file].presence || params.dig(:document, :file).presence || params.dig(:driver_document, :file).presence
    doc.file.attach(file) if file.present?
    doc.save!

    render json: payload(doc), status: :created
  end

  def update
    doc = @profile.driver_documents.find(params[:id])
    authorize doc, :update?

    doc.assign_attributes(document_params)
    file = params[:file].presence || params.dig(:document, :file).presence || params.dig(:driver_document, :file).presence
    doc.file.attach(file) if file.present?
    doc.save!

    render json: payload(doc)
  end

  def verify
    doc = @profile.driver_documents.find(params[:id])
    authorize doc, :verify?

    status = params.require(:verification_status)
    updates = {
      verification_status: status,
      notes: [doc.notes, params[:notes]].compact.join("\n")
    }
    updates[:verified_by] = current_user.id if doc.has_attribute?(:verified_by)
    updates[:verified_at] = Time.current if doc.has_attribute?(:verified_at)
    doc.update!(updates)

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
    source =
      params[:document].presence ||
      params[:driver_document].presence ||
      params

    scoped_params =
      if source.is_a?(ActionController::Parameters)
        source
      else
        ActionController::Parameters.new(source || {})
      end

    permitted = scoped_params.permit(
      :document_type,
      :document_number,
      :title,
      :issued_at,
      :issued_date,
      :expires_at,
      :expiry_date,
      :issuing_authority,
      :status,
      :notify_before_days,
      :verification_status,
      :cost,
      :notes,
      metadata: {}
    )
    permitted[:issued_at] = permitted[:issued_at].presence || permitted.delete(:issued_date)
    permitted[:expires_at] = permitted[:expires_at].presence || permitted.delete(:expiry_date)
    permitted[:document_type] = normalize_document_type(permitted[:document_type])
    permitted[:notify_before_days] = 30 if permitted[:notify_before_days].blank?
    permitted
  end

  def normalize_document_type(value)
    return value if value.blank?

    normalized = value.to_s.downcase.strip
    case normalized
    when "license", "driving license", "driving_licence", "driving_licence_card"
      "driving_license"
    when "medical", "medical certificate", "medical fitness"
      "medical_fitness_certificate"
    when "insurance", "insurance coverage"
      "insurance_coverage"
    else
      normalized.tr(" ", "_")
    end
  end

  def payload(doc)
    verified_by_value =
      if doc.respond_to?(:verified_by)
        doc.verified_by
      elsif doc.respond_to?(:verified_by_id)
        doc.verified_by_id
      else
        nil
      end
    verified_at_value = doc.respond_to?(:verified_at) ? doc.verified_at : nil

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
      verified_by: verified_by_value,
      verified_at: verified_at_value,
      cost: doc.cost,
      notes: doc.notes,
      file_url: blob_url_for(doc.file)
    }
  end
end

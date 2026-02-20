class Incidents::EvidenceController < ApplicationController
  include Rails.application.routes.url_helpers

  before_action :set_incident

  def create
    authorize @incident, :update?

    evidence = @incident.evidence_items.new(evidence_params.except(:file))
    evidence.uploader = current_user
    evidence.file.attach(evidence_params[:file]) if evidence_params[:file].present?
    evidence.save!

    audit(action: "incident.evidence_added", auditable: @incident, associated: evidence)

    render json: evidence_payload(evidence), status: :created
  end

  def index
    authorize @incident, :show?

    render json: {
      data: @incident.evidence_items.order(created_at: :asc).map { |e| evidence_payload(e) }
    }
  end

  private

  def set_incident
    @incident = Incident.find(params[:incident_id])
  end

  def evidence_params
    params.require(:evidence).permit(:evidence_type, :category, :title, :captured_at, :latitude, :longitude, :notes, :file, metadata: {})
  end

  def evidence_payload(evidence)
    {
      id: evidence.id,
      evidence_type: evidence.evidence_type,
      category: evidence.category,
      title: evidence.title,
      captured_at: evidence.captured_at,
      latitude: evidence.latitude,
      longitude: evidence.longitude,
      notes: evidence.notes,
      metadata: evidence.metadata,
      file_url: evidence.file.attached? ? rails_blob_url(evidence.file, only_path: true) : nil
    }
  end
end

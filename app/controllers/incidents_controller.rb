class IncidentsController < ApplicationController
  before_action :set_incident, only: [:show, :update, :update_status]

  def index
    authorize Incident, :index?

    scope = Incident.includes(:vehicle, :driver, :trip).order(incident_date: :desc)
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(incident_type: params[:incident_type]) if params[:incident_type].present?
    scope = scope.where(severity: params[:severity]) if params[:severity].present?
    scope = scope.where(vehicle_id: params[:vehicle_id]) if params[:vehicle_id].present?
    scope = scope.where(driver_id: params[:driver_id]) if params[:driver_id].present?
    scope = scope.where(trip_id: params[:trip_id]) if params[:trip_id].present?

    page = params[:page].to_i.positive? ? params[:page].to_i : 1
    per_page = [params[:per_page].to_i.positive? ? params[:per_page].to_i : 25, 100].min

    render json: {
      data: scope.offset((page - 1) * per_page).limit(per_page).map { |incident| payload(incident) },
      meta: { page: page, per_page: per_page, total: scope.count }
    }
  end

  def show
    authorize @incident, :show?

    render json: detail_payload(@incident)
  end

  def create
    authorize Incident, :create?

    incident = Incident.new(incident_params)
    incident.reporter = current_user
    incident.incident_date ||= Time.current
    set_audit_actor(incident)
    incident.save!

    NotificationService.notify(
      notification_type: "system.announcement",
      recipients: ["admin", "supervisor"],
      actor: current_user,
      notifiable: incident,
      priority: incident.severity == "critical" ? "critical" : "high",
      data: { title: "Incident Reported", message: "#{incident.incident_number} - #{incident.title}" }
    )

    audit(action: "incident.created", auditable: incident, metadata: { severity: incident.severity, incident_type: incident.incident_type })

    render json: detail_payload(incident), status: :created
  end

  def update
    authorize @incident, :update?

    if @incident.status == "closed"
      return render json: { error: "Closed incident cannot be edited. Reopen first." }, status: :unprocessable_entity
    end

    set_audit_actor(@incident)
    @incident.update!(incident_params)
    audit(action: "incident.updated", auditable: @incident)

    render json: detail_payload(@incident)
  end

  def update_status
    authorize @incident, :update?

    new_status = params.require(:status).to_s
    notes = params[:notes]
    validate_status_requirements!(@incident, new_status)
    from_status = @incident.status
    @incident.transition_status!(new_status: new_status, actor: current_user, notes: notes)

    case new_status
    when "investigating"
      audit(action: "incident.investigation_started", auditable: @incident, changes: { status: { from: from_status, to: new_status } })
    when "resolved"
      audit(action: "incident.resolved", auditable: @incident, changes: { status: { from: from_status, to: new_status } })
    else
      audit(action: "incident.status_changed", auditable: @incident, changes: { status: { from: from_status, to: new_status } })
    end

    render json: detail_payload(@incident.reload)
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def dashboard
    authorize Incident, :dashboard?

    scope = Incident.all
    this_month = scope.where(incident_date: Date.current.beginning_of_month.beginning_of_day..Time.current)

    resolved_with_dates = scope.where(status: %w[resolved closed]).where.not(created_at: nil, resolved_at: nil)
    avg_resolution_days = resolved_with_dates.average("EXTRACT(EPOCH FROM (resolved_at - created_at)) / 86400.0")

    render json: {
      total_incidents: scope.count,
      open_incidents: scope.where(status: %w[reported acknowledged investigating reopened]).count,
      this_month: this_month.count,
      by_severity: scope.group(:severity).count,
      by_type: scope.group(:incident_type).count,
      total_damage_cost: scope.sum(:actual_damage_cost).to_d,
      total_insurance_recovered: InsuranceClaim.where(status: %w[approved partially_approved settled]).sum(:approved_amount).to_d,
      average_resolution_days: avg_resolution_days.to_d.round(2),
      unresolved_claims: InsuranceClaim.where.not(status: %w[settled withdrawn]).count,
      pending_investigations: scope.where(status: "investigating").count
    }
  end

  private

  def set_incident
    @incident = Incident.find(params[:id])
  end

  def incident_params
    params.require(:incident).permit(
      :trip_id, :vehicle_id, :driver_id, :incident_type, :severity, :status, :title, :description,
      :incident_date, :incident_location, :latitude, :longitude, :weather_conditions, :road_conditions,
      :injuries_reported, :injuries_description, :fatalities, :third_party_involved, :third_party_details,
      :police_report_number, :police_station, :estimated_damage_cost, :actual_damage_cost,
      :vehicle_damage_description, :cargo_damage_description, :cargo_damage_value,
      :vehicle_drivable, :towing_required, :root_cause, :root_cause_category,
      :corrective_actions, :preventive_measures, :assigned_investigator_id,
      :investigation_started_at, :investigation_completed_at, :resolved_at, :resolved_by, :closure_notes,
      metadata: {}
    )
  end

  def validate_status_requirements!(incident, new_status)
    case new_status
    when "investigating"
      raise ArgumentError, "assigned_investigator_id is required" if incident.assigned_investigator_id.blank?
    when "resolved"
      raise ArgumentError, "root_cause is required" if incident.root_cause.blank?
      raise ArgumentError, "root_cause_category is required" if incident.root_cause_category.blank?
      raise ArgumentError, "corrective_actions is required" if incident.corrective_actions.blank?
    when "closed"
      unresolved_claims = incident.insurance_claims.where.not(status: %w[settled withdrawn]).exists?
      raise ArgumentError, "closure_notes is required" if incident.closure_notes.blank?
      raise ArgumentError, "insurance claims must be settled or withdrawn before closing" if unresolved_claims
    when "reopened"
      raise ArgumentError, "notes are required when reopening" if params[:notes].blank?
    end
  end

  def payload(incident)
    {
      id: incident.id,
      incident_number: incident.incident_number,
      trip_id: incident.trip_id,
      vehicle_id: incident.vehicle_id,
      driver_id: incident.driver_id,
      incident_type: incident.incident_type,
      severity: incident.severity,
      status: incident.status,
      title: incident.title,
      incident_date: incident.incident_date,
      location: incident.incident_location,
      estimated_damage_cost: incident.estimated_damage_cost,
      actual_damage_cost: incident.actual_damage_cost,
      created_at: incident.created_at
    }
  end

  def detail_payload(incident)
    payload(incident).merge(
      description: incident.description,
      metadata: incident.metadata,
      witnesses: incident.witnesses.order(created_at: :asc).map { |w| witness_payload(w) },
      evidence: incident.evidence_items.order(created_at: :asc).map { |e| evidence_payload(e) },
      comments: incident.comments.order(created_at: :asc).map { |c| comment_payload(c) },
      insurance_claims: incident.insurance_claims.order(created_at: :asc).map { |claim| insurance_claim_payload(claim) },
      audit_logs: AuditLog.where(auditable: incident).or(AuditLog.where(associated: incident)).order(occurred_at: :desc).limit(200).map do |log|
        { id: log.id, action: log.action, severity: log.severity, description: log.description, occurred_at: log.occurred_at }
      end
    )
  end

  def witness_payload(witness)
    {
      id: witness.id,
      name: witness.name,
      phone: witness.phone,
      email: witness.email,
      relationship: witness.relationship,
      statement: witness.statement,
      statement_date: witness.statement_date,
      notes: witness.notes
    }
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
      file_url: evidence.file.attached? ? Rails.application.routes.url_helpers.rails_blob_url(evidence.file, only_path: true) : nil
    }
  end

  def comment_payload(comment)
    {
      id: comment.id,
      comment: comment.comment,
      comment_type: comment.comment_type,
      metadata: comment.metadata,
      user: { id: comment.user_id, name: comment.user&.name },
      created_at: comment.created_at
    }
  end

  def insurance_claim_payload(claim)
    {
      id: claim.id,
      claim_number: claim.claim_number,
      policy_number: claim.policy_number,
      insurer_name: claim.insurer_name,
      claim_type: claim.claim_type,
      claimed_amount: claim.claimed_amount,
      approved_amount: claim.approved_amount,
      deductible: claim.deductible,
      status: claim.status,
      filed_at: claim.filed_at,
      settled_at: claim.settled_at,
      notes: claim.notes
    }
  end
end

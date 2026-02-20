class Compliance::ViolationsController < ApplicationController
  def index
    authorize ComplianceViolation, :index?

    scope = ComplianceViolation.includes(:compliance_requirement).order(created_at: :desc)
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(severity: params[:severity]) if params[:severity].present?
    scope = scope.where(violatable_type: params[:violatable_type].to_s.classify) if params[:violatable_type].present?
    scope = scope.where(violatable_id: params[:violatable_id]) if params[:violatable_id].present?
    scope = scope.where(compliance_requirement_id: params[:requirement_id]) if params[:requirement_id].present?

    render json: { data: scope.limit(1000).map { |violation| payload(violation) } }
  end

  def show
    violation = ComplianceViolation.find(params[:id])
    authorize violation, :show?

    render json: payload(violation).merge(
      requirement: {
        id: violation.compliance_requirement_id,
        code: violation.compliance_requirement&.code,
        name: violation.compliance_requirement&.name,
        category: violation.compliance_requirement&.category
      },
      check: {
        id: violation.compliance_check_id,
        result: violation.compliance_check&.result,
        checked_at: violation.compliance_check&.checked_at,
        details: violation.compliance_check&.details
      },
      waiver: violation.compliance_waiver && waiver_payload(violation.compliance_waiver)
    )
  end

  def update
    violation = ComplianceViolation.find(params[:id])
    authorize violation, :update?

    from_status = violation.status
    violation.update!(violation_params)
    if from_status != violation.status
      audit(action: "compliance.violation_resolved", auditable: violation, changes: { status: { from: from_status, to: violation.status } })
    end

    render json: payload(violation)
  end

  def waiver
    violation = ComplianceViolation.find(params[:id])
    authorize violation, :waiver?

    waiver = violation.compliance_waiver || violation.build_compliance_waiver
    waiver.assign_attributes(waiver_params)
    waiver.status = "approved"
    waiver.approver = current_user
    waiver.approved_at = Time.current
    waiver.save!

    violation.update!(
      status: "waived",
      waiver_reason: waiver.reason,
      waiver_approved_by: current_user.id,
      waiver_expires_at: waiver.effective_until
    )

    audit(action: "compliance.waiver_granted", auditable: violation, associated: waiver, metadata: { effective_until: waiver.effective_until })

    render json: waiver_payload(waiver), status: :created
  end

  private

  def violation_params
    params.require(:compliance_violation).permit(
      :severity, :status, :description, :required_action, :deadline,
      :resolved_at, :resolved_by, :resolution_notes, :waiver_reason,
      :waiver_expires_at, :financial_penalty, metadata: {}
    )
  end

  def waiver_params
    params.require(:waiver).permit(:reason, :conditions, :risk_assessment, :effective_from, :effective_until, metadata: {})
  end

  def payload(violation)
    {
      id: violation.id,
      violation_number: violation.violation_number,
      compliance_requirement_id: violation.compliance_requirement_id,
      compliance_check_id: violation.compliance_check_id,
      violatable_type: violation.violatable_type,
      violatable_id: violation.violatable_id,
      trip_id: violation.trip_id,
      severity: violation.severity,
      status: violation.status,
      description: violation.description,
      required_action: violation.required_action,
      deadline: violation.deadline,
      resolved_at: violation.resolved_at,
      resolved_by: violation.resolved_by,
      resolution_notes: violation.resolution_notes,
      waiver_reason: violation.waiver_reason,
      waiver_expires_at: violation.waiver_expires_at,
      financial_penalty: violation.financial_penalty,
      linked_incident_id: violation.linked_incident_id,
      metadata: violation.metadata,
      created_at: violation.created_at,
      updated_at: violation.updated_at
    }
  end

  def waiver_payload(waiver)
    {
      id: waiver.id,
      waiver_number: waiver.waiver_number,
      reason: waiver.reason,
      conditions: waiver.conditions,
      risk_assessment: waiver.risk_assessment,
      approved_by: waiver.approved_by,
      approved_at: waiver.approved_at,
      effective_from: waiver.effective_from,
      effective_until: waiver.effective_until,
      status: waiver.status,
      metadata: waiver.metadata
    }
  end
end

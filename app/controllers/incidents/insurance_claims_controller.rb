class Incidents::InsuranceClaimsController < ApplicationController
  before_action :set_incident

  def create
    authorize @incident, :update?

    claim = @incident.insurance_claims.new(insurance_claim_params)
    claim.filer = current_user
    claim.save!

    audit(action: "incident.insurance_claimed", auditable: @incident, associated: claim)

    render json: payload(claim), status: :created
  end

  def update
    authorize @incident, :update?

    claim = @incident.insurance_claims.find(params[:claim_id])
    claim.update!(insurance_claim_params)

    audit(action: "incident.updated", auditable: @incident, associated: claim, metadata: { updated: "insurance_claim" })

    render json: payload(claim)
  end

  private

  def set_incident
    @incident = Incident.find(params[:incident_id])
  end

  def insurance_claim_params
    params.require(:insurance_claim).permit(
      :policy_number, :insurer_name, :insurer_contact, :claim_type, :claimed_amount,
      :approved_amount, :deductible, :status, :filed_at, :settled_at, :denial_reason,
      :settlement_notes, :notes, metadata: {}, documents: []
    )
  end

  def payload(claim)
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

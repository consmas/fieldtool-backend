class Incidents::WitnessesController < ApplicationController
  before_action :set_incident

  def create
    authorize @incident, :update?

    witness = @incident.witnesses.create!(witness_params)
    audit(action: "incident.updated", auditable: @incident, associated: witness, metadata: { added: "witness" })

    render json: { id: witness.id, name: witness.name, relationship: witness.relationship }, status: :created
  end

  def update
    authorize @incident, :update?

    witness = @incident.witnesses.find(params[:witness_id])
    witness.update!(witness_params)
    audit(action: "incident.updated", auditable: @incident, associated: witness, metadata: { updated: "witness" })

    render json: { id: witness.id, name: witness.name, relationship: witness.relationship }
  end

  private

  def set_incident
    @incident = Incident.find(params[:incident_id])
  end

  def witness_params
    params.require(:witness).permit(:name, :phone, :email, :relationship, :statement, :statement_date, :notes)
  end
end

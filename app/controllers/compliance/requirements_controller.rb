class Compliance::RequirementsController < ApplicationController
  def index
    authorize ComplianceRequirement, :index?

    scope = ComplianceRequirement.order(priority: :asc, name: :asc)
    scope = scope.where(category: params[:category]) if params[:category].present?
    scope = scope.where(applies_to: params[:applies_to]) if params[:applies_to].present?
    scope = scope.where(enforcement_level: params[:enforcement_level]) if params[:enforcement_level].present?
    scope = scope.where(jurisdiction: params[:jurisdiction]) if params[:jurisdiction].present?
    scope = scope.where(is_active: ActiveModel::Type::Boolean.new.cast(params[:is_active])) if params[:is_active].present?

    render json: { data: scope.map { |item| payload(item) } }
  end

  def create
    authorize ComplianceRequirement, :create?

    requirement = ComplianceRequirement.new(requirement_params)
    set_audit_actor(requirement)
    requirement.save!
    audit(action: "system.config_changed", auditable: requirement, metadata: { config: "compliance_requirement_created" })

    render json: payload(requirement), status: :created
  end

  def update
    requirement = ComplianceRequirement.find(params[:id])
    authorize requirement, :update?

    set_audit_actor(requirement)
    requirement.update!(requirement_params)
    audit(action: "system.config_changed", auditable: requirement, metadata: { config: "compliance_requirement_updated" })

    render json: payload(requirement)
  end

  private

  def requirement_params
    params.require(:compliance_requirement).permit(
      :name, :code, :category, :applies_to, :description, :regulation_reference,
      :jurisdiction, :enforcement_level, :check_type, :check_frequency, :auto_check,
      :penalty_description, :is_active, :priority,
      auto_check_config: {}, metadata: {}
    )
  end

  def payload(item)
    {
      id: item.id,
      name: item.name,
      code: item.code,
      category: item.category,
      applies_to: item.applies_to,
      description: item.description,
      regulation_reference: item.regulation_reference,
      jurisdiction: item.jurisdiction,
      enforcement_level: item.enforcement_level,
      check_type: item.check_type,
      check_frequency: item.check_frequency,
      auto_check: item.auto_check,
      auto_check_config: item.auto_check_config,
      penalty_description: item.penalty_description,
      is_active: item.is_active,
      priority: item.priority,
      metadata: item.metadata
    }
  end
end

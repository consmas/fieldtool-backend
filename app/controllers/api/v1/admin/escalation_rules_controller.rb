class Api::V1::Admin::EscalationRulesController < ApplicationController
  def index
    authorize :webhook_admin, :show?

    render json: { data: EscalationRule.order(created_at: :desc).map { |rule| payload(rule) } }
  end

  def create
    authorize :webhook_admin, :show?

    rule = EscalationRule.create!(rule_params)
    render json: payload(rule), status: :created
  end

  def update
    authorize :webhook_admin, :show?

    rule = EscalationRule.find(params[:id])
    rule.update!(rule_params)
    render json: payload(rule)
  end

  private

  def rule_params
    params.require(:escalation_rule).permit(
      :name,
      :trigger_event,
      :condition_type,
      :condition_minutes,
      :escalation_level,
      :escalate_to_role,
      :escalate_to_user_id,
      :escalation_priority,
      :escalation_message,
      :max_escalations,
      :is_active,
      escalation_channels: []
    )
  end

  def payload(rule)
    {
      id: rule.id,
      name: rule.name,
      trigger_event: rule.trigger_event,
      condition_type: rule.condition_type,
      condition_minutes: rule.condition_minutes,
      escalation_level: rule.escalation_level,
      escalate_to_role: rule.escalate_to_role,
      escalate_to_user_id: rule.escalate_to_user_id,
      escalation_channels: rule.escalation_channels,
      escalation_priority: rule.escalation_priority,
      escalation_message: rule.escalation_message,
      max_escalations: rule.max_escalations,
      is_active: rule.is_active
    }
  end
end

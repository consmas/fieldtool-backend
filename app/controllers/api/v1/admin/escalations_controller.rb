class Api::V1::Admin::EscalationsController < ApplicationController
  def active
    authorize :webhook_admin, :show?

    records = EscalationInstance.active.includes(:notification, :escalation_rule).order(created_at: :desc)
    render json: {
      data: records.map do |row|
        {
          id: row.id,
          escalation_rule: {
            id: row.escalation_rule_id,
            name: row.escalation_rule&.name,
            trigger_event: row.escalation_rule&.trigger_event
          },
          notification: {
            id: row.notification_id,
            notification_type: row.notification&.notification_type,
            title: row.notification&.title,
            recipient_id: row.notification&.recipient_id
          },
          notifiable_type: row.notifiable_type,
          notifiable_id: row.notifiable_id,
          current_level: row.current_level,
          status: row.status,
          last_escalated_at: row.last_escalated_at,
          created_at: row.created_at
        }
      end
    }
  end
end

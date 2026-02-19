module Notifications
  class ProcessEscalationsJob < ApplicationJob
    queue_as :default

    def perform
      EscalationInstance.active.includes(:escalation_rule, :notification).find_each do |instance|
        rule = instance.escalation_rule
        notification = instance.notification
        next if rule.nil? || notification.nil?

        if notification.read_at.present?
          instance.update!(status: "resolved", resolved_at: Time.current)
          next
        end

        reference_time = instance.last_escalated_at || instance.created_at
        next unless Time.current >= reference_time + rule.condition_minutes.minutes

        if instance.current_level >= rule.max_escalations
          instance.update!(status: "max_reached")
          next
        end

        recipients = resolve_recipients(rule)
        NotificationService.notify(
          notification_type: "system.escalation",
          recipients: recipients,
          notifiable: instance.notifiable,
          data: {
            original_type: notification.notification_type,
            escalation_level: instance.current_level + 1,
            original_message: notification.body,
            time_unactioned: "#{rule.condition_minutes * (instance.current_level + 1)} minutes"
          },
          priority: rule.escalation_priority
        )

        instance.update!(
          current_level: instance.current_level + 1,
          last_escalated_at: Time.current
        )
      end
    end

    private

    def resolve_recipients(rule)
      return [rule.escalate_to_user_id] if rule.escalate_to_user_id.present?
      return [] if rule.escalate_to_role.blank?

      [rule.escalate_to_role]
    end
  end
end

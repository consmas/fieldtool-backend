class NotificationService
  class << self
    def notify(notification_type:, recipients:, actor: nil, notifiable: nil, data: {}, priority: nil, group_key: nil, expires_at: nil)
      config = NotificationTypeRegistry.fetch(notification_type)
      raise ArgumentError, "Unknown notification type: #{notification_type}" if config.blank?

      recipient_users = resolve_recipients(recipients, fallback_roles: config[:roles], actor: actor)
      return [] if recipient_users.empty?

      recipient_users.map do |user|
        pref = NotificationPreference.find_or_initialize_by(user_id: user.id, notification_type: notification_type)
        apply_default_preference(pref, config)
        next if pref.is_enabled == false

        title = interpolate(config[:title_template], data)
        body = interpolate(config[:body_template], data)

        channels = resolved_channels(config: config, preference: pref, priority: priority || config[:priority], now: Time.current)

        notification = Notification.create!(
          recipient_id: user.id,
          actor_id: actor&.id,
          notification_type: notification_type,
          category: config[:category],
          title: title,
          body: body,
          priority: (priority || config[:priority]),
          notifiable: notifiable,
          action_url: data[:action_url],
          action_type: data[:action_type],
          data: data,
          group_key: group_key,
          expires_at: expires_at,
          delivered_via: channels.keys.select { |k| channels[k] }.map(&:to_s)
        )

        enqueue_channels(notification, channels)
        create_escalation_if_needed(notification)
        emit_webhook(notification)

        notification
      end.compact
    end

    def broadcast(notification_type:, data:, recipient_roles: ["all"])
      notify(notification_type: notification_type, recipients: recipient_roles, data: data)
    end

    def resolve_escalation(notifiable:, resolved_by:)
      scope = EscalationInstance.active
      scope = scope.where(notifiable_type: notifiable.class.name, notifiable_id: notifiable.id) if notifiable.present?

      scope.update_all(status: "resolved", resolved_at: Time.current, resolved_by: resolved_by.id)
    end

    private

    def resolve_recipients(recipients, fallback_roles:, actor:)
      set = []
      values = Array(recipients.presence || fallback_roles)

      values.each do |entry|
        case entry
        when Integer
          user = User.find_by(id: entry)
          set << user if user
        when User
          set << entry
        when Symbol, String
          role = entry.to_s
          if role == "all"
            set.concat(User.all)
          elsif User.roles.key?(role)
            set.concat(User.where(role: role))
          end
        end
      end

      set.compact.uniq.reject { |u| actor.present? && u.id == actor.id }
    end

    def apply_default_preference(pref, config)
      return if pref.persisted?

      pref.assign_attributes(config.fetch(:default_channels).slice(:in_app, :push, :sms, :email).merge(is_enabled: true))
      pref.save!
    end

    def resolved_channels(config:, preference:, priority:, now:)
      defaults = config[:default_channels]
      channels = {
        in_app: preference.in_app.nil? ? defaults[:in_app] : preference.in_app,
        push: preference.push.nil? ? defaults[:push] : preference.push,
        sms: preference.sms.nil? ? defaults[:sms] : preference.sms,
        email: preference.email.nil? ? defaults[:email] : preference.email
      }

      return channels if priority.to_s == "critical"

      if within_quiet_hours?(preference, now)
        channels[:push] = false
        channels[:sms] = false
      end

      channels
    end

    def within_quiet_hours?(pref, now)
      return false if pref.quiet_hours_start.blank? || pref.quiet_hours_end.blank?

      current = now.seconds_since_midnight
      start_seconds = pref.quiet_hours_start.seconds_since_midnight
      end_seconds = pref.quiet_hours_end.seconds_since_midnight

      if start_seconds <= end_seconds
        current >= start_seconds && current < end_seconds
      else
        current >= start_seconds || current < end_seconds
      end
    end

    def enqueue_channels(notification, channels)
      Notifications::InAppNotificationJob.perform_later(notification.id) if channels[:in_app]
      Notifications::DeliverPushNotificationJob.perform_later(notification.id) if channels[:push]
      Notifications::DeliverSmsNotificationJob.perform_later(notification.id) if channels[:sms]
      Notifications::DeliverEmailNotificationJob.perform_later(notification.id) if channels[:email]
    end

    def create_escalation_if_needed(notification)
      EscalationRule.active.where(trigger_event: notification.notification_type).find_each do |rule|
        EscalationInstance.create!(
          escalation_rule_id: rule.id,
          notification_id: notification.id,
          notifiable: notification.notifiable,
          current_level: 0,
          status: "active"
        )
      end
    end

    def emit_webhook(notification)
      WebhookEventService.emit(
        "system.announcement",
        resource: notification,
        payload: {
          id: notification.id,
          notification_type: notification.notification_type,
          recipient_id: notification.recipient_id,
          category: notification.category,
          priority: notification.priority,
          title: notification.title,
          body: notification.body
        }
      )
    rescue StandardError
      nil
    end

    def interpolate(template, data)
      template.to_s % data.with_indifferent_access
    rescue KeyError
      template.to_s
    end
  end
end

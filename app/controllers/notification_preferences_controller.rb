class NotificationPreferencesController < ApplicationController
  def index
    prefs = current_user.notification_preferences.index_by(&:notification_type)
    data = NotificationTypeRegistry.keys.map do |type|
      config = NotificationTypeRegistry.fetch(type)
      pref = prefs[type]
      {
        notification_type: type,
        in_app: pref&.in_app.nil? ? config[:default_channels][:in_app] : pref.in_app,
        push: pref&.push.nil? ? config[:default_channels][:push] : pref.push,
        sms: pref&.sms.nil? ? config[:default_channels][:sms] : pref.sms,
        email: pref&.email.nil? ? config[:default_channels][:email] : pref.email,
        is_enabled: pref&.is_enabled.nil? ? true : pref.is_enabled,
        quiet_hours_start: pref&.quiet_hours_start,
        quiet_hours_end: pref&.quiet_hours_end
      }
    end

    render json: { data: data }
  end

  def update
    list = params.require(:preferences)

    NotificationPreference.transaction do
      list.each do |row|
        attrs = row.to_h.with_indifferent_access
        pref = current_user.notification_preferences.find_or_initialize_by(notification_type: attrs.fetch(:notification_type))
        pref.assign_attributes(attrs.slice(:in_app, :push, :sms, :email, :is_enabled, :quiet_hours_start, :quiet_hours_end))
        pref.save!
      end
    end

    head :no_content
  end

  def quiet_hours
    start_value = params.require(:start)
    end_value = params.require(:end)

    NotificationTypeRegistry.keys.each do |type|
      pref = current_user.notification_preferences.find_or_initialize_by(notification_type: type)
      config = NotificationTypeRegistry.fetch(type)
      if pref.new_record?
        pref.in_app = config[:default_channels][:in_app]
        pref.push = config[:default_channels][:push]
        pref.sms = config[:default_channels][:sms]
        pref.email = config[:default_channels][:email]
        pref.is_enabled = true
      end
      pref.update!(quiet_hours_start: start_value, quiet_hours_end: end_value)
    end

    render json: { start: start_value, end: end_value }
  end
end

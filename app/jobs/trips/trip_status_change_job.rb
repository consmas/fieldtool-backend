module Trips
  class TripStatusChangeJob < ApplicationJob
    queue_as :critical

    def perform(trip_id, old_status, new_status, actor_id = nil)
      trip = Trip.find_by(id: trip_id)
      return if trip.nil?

      actor = User.find_by(id: actor_id) if actor_id.present?

      WebhookEventService.emit(
        "trip.status_changed",
        resource: trip,
        payload: Webhooks::TripWebhookSerializer.new(trip).as_json.merge(from_status: old_status, to_status: new_status),
        triggered_by: actor
      )

      specific_event = case new_status.to_s
      when "en_route" then "trip.started"
      when "completed" then "trip.completed"
      when "cancelled" then "trip.cancelled"
      when "assigned" then "trip.assigned"
      end

      if specific_event
        WebhookEventService.emit(
          specific_event,
          resource: trip,
          payload: Webhooks::TripWebhookSerializer.new(trip).as_json,
          triggered_by: actor
        )
      end

      Expenses::AutoGenerateRoadExpenseJob.perform_later(trip.id, actor&.id) if new_status.to_s == "en_route"
      Trips::TripCompletionJob.perform_later(trip.id, actor&.id) if new_status.to_s == "completed"
      notification_type = case new_status.to_s
      when "assigned" then "trip.assigned"
      when "en_route" then "trip.started"
      when "completed" then "trip.completed"
      else nil
      end
      if notification_type
        NotificationService.notify(
          notification_type: notification_type,
          recipients: [trip.driver_id],
          actor: actor,
          notifiable: trip,
          data: {
            trip_number: trip.reference_code || "TRIP-#{trip.id}",
            origin: trip.loading_point.presence || "N/A",
            destination: trip.destination.presence || "N/A",
            distance_km: trip.distance_km.to_d
          }
        )
      end
    end
  end
end

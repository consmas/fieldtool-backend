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
      Notifications::InAppNotificationJob.perform_later(
        recipient_user_id: trip.driver_id,
        kind: "trip_status_changed",
        payload: { trip_id: trip.id, from: old_status, to: new_status }
      )
    end
  end
end

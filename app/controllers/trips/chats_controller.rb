class Trips::ChatsController < ApplicationController
  def show
    trip = Trip.find(params[:trip_id])
    authorize trip, :show?

    thread = find_or_initialize_thread(trip)
    return render json: { error: ["Not authorized for chat"] }, status: :forbidden unless thread.participant?(current_user)

    render json: thread_payload(thread)
  end

  private

  def find_or_initialize_thread(trip)
    trip.chat_thread || trip.build_chat_thread(driver: trip.driver, dispatcher: trip.dispatcher)
  end

  def thread_payload(thread)
    {
      id: thread.id,
      trip_id: thread.trip_id,
      driver_id: thread.driver_id,
      dispatcher_id: thread.dispatcher_id,
      last_message_at: thread.last_message_at,
      messages: thread.messages.order(created_at: :asc).map { |message| message_payload(message) }
    }
  end

  def message_payload(message)
    {
      id: message.id,
      chat_thread_id: message.chat_thread_id,
      sender_id: message.sender_id,
      body: message.body,
      read_at: message.read_at,
      created_at: message.created_at
    }
  end
end

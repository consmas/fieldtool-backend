class Trips::ChatMessagesController < ApplicationController
  def create
    trip = Trip.find(params[:trip_id])
    authorize trip, :show?

    thread = ensure_thread!(trip)
    return render json: { error: ["Not authorized for chat"] }, status: :forbidden unless thread.participant?(current_user)

    message = thread.messages.create!(
      sender: current_user,
      body: params.require(:message).permit(:body)[:body]
    )

    TripEvent.create!(
      trip: trip,
      event_type: "chat_message_sent",
      message: "Chat message sent",
      created_by: current_user,
      data: { chat_thread_id: thread.id, chat_message_id: message.id }
    )

    render json: message_payload(message), status: :created
  end

  def update
    trip = Trip.find(params[:trip_id])
    authorize trip, :show?

    thread = trip.chat_thread
    return render json: { error: ["Chat thread not found"] }, status: :not_found if thread.nil?
    return render json: { error: ["Not authorized for chat"] }, status: :forbidden unless thread.participant?(current_user)

    message = thread.messages.find(params[:id])
    if message.sender_id != current_user.id && message.read_at.nil?
      message.update!(read_at: Time.current)
    end

    render json: message_payload(message)
  end

  private

  def ensure_thread!(trip)
    trip.chat_thread || trip.create_chat_thread!(driver: trip.driver, dispatcher: trip.dispatcher)
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

class Chats::ConversationMessagesController < ApplicationController
  def create
    conversation = current_user.chat_conversations.find(params[:conversation_id])
    message = conversation.messages.create!(
      sender: current_user,
      body: message_params[:body]
    )

    render json: message_payload(message), status: :created
  end

  private

  def message_params
    params.require(:message).permit(:body)
  end

  def message_payload(message)
    {
      id: message.id,
      conversation_id: message.conversation_id,
      sender_id: message.sender_id,
      body: message.body,
      created_at: message.created_at
    }
  end
end

class Chats::ConversationsController < ApplicationController
  def index
    conversations = current_user.chat_conversations.includes(:participants, :messages).order(last_message_at: :desc, updated_at: :desc)
    render json: conversations.map { |conversation| conversation_payload(conversation) }
  end

  def create
    participant_ids = normalize_participant_ids
    return render json: { error: ["At least one participant is required"] }, status: :unprocessable_entity if participant_ids.empty?

    users = User.where(id: participant_ids)
    return render json: { error: ["One or more participants are invalid"] }, status: :unprocessable_entity if users.count != participant_ids.size

    if participant_ids.size == 2
      existing = find_direct_conversation(participant_ids)
      return render json: conversation_payload(existing) if existing
    end

    conversation = ChatConversation.new(
      kind: participant_ids.size > 2 ? :group : :direct,
      title: params.dig(:conversation, :title),
      created_by: current_user
    )

    ChatConversation.transaction do
      conversation.save!
      participant_ids.each { |user_id| conversation.participants.create!(user_id: user_id) }
    end

    render json: conversation_payload(conversation), status: :created
  end

  def show
    conversation = scoped_conversations.find(params[:id])
    render json: conversation_payload(conversation, include_messages: true)
  end

  def mark_read
    conversation = scoped_conversations.find(params[:id])
    participant = conversation.participants.find_by!(user_id: current_user.id)
    participant.update!(last_read_at: Time.current)

    render json: { id: conversation.id, last_read_at: participant.last_read_at }
  end

  private

  def scoped_conversations
    current_user.chat_conversations
  end

  def normalize_participant_ids
    ids = Array(params.dig(:conversation, :participant_ids)).map(&:to_i).uniq
    ids << current_user.id
    ids.uniq
  end

  def find_direct_conversation(participant_ids)
    ChatConversation
      .kind_direct
      .joins(:participants)
      .where(chat_conversation_participants: { user_id: participant_ids })
      .group("chat_conversations.id")
      .having("COUNT(DISTINCT chat_conversation_participants.user_id) = ?", participant_ids.size)
      .detect { |conversation| conversation.participants.count == participant_ids.size }
  end

  def conversation_payload(conversation, include_messages: false)
    payload = {
      id: conversation.id,
      kind: conversation.kind,
      title: conversation.title,
      created_by_id: conversation.created_by_id,
      last_message_at: conversation.last_message_at,
      participants: conversation.participants.includes(:user).map do |participant|
        {
          user_id: participant.user_id,
          name: participant.user.name,
          email: participant.user.email,
          role: participant.user.role,
          last_read_at: participant.last_read_at
        }
      end,
      unread_count: unread_count_for(conversation)
    }

    payload[:messages] = conversation.messages.order(created_at: :asc).map { |message| message_payload(message) } if include_messages
    payload
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

  def unread_count_for(conversation)
    participant = conversation.participants.find { |entry| entry.user_id == current_user.id }
    return 0 if participant.nil?

    scope = conversation.messages.where.not(sender_id: current_user.id)
    participant.last_read_at.present? ? scope.where("created_at > ?", participant.last_read_at).count : scope.count
  end
end

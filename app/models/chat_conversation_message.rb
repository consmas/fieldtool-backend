class ChatConversationMessage < ApplicationRecord
  belongs_to :conversation, class_name: "ChatConversation", inverse_of: :messages
  belongs_to :sender, class_name: "User"

  validates :body, presence: true, length: { maximum: 2000 }
  validate :sender_is_participant

  after_create_commit :set_conversation_last_message_at

  private

  def sender_is_participant
    return if conversation&.participant?(sender)

    errors.add(:sender, "is not a participant in this conversation")
  end

  def set_conversation_last_message_at
    conversation.touch_last_message_at!(created_at)
  end
end

class ChatConversationParticipant < ApplicationRecord
  belongs_to :conversation, class_name: "ChatConversation", inverse_of: :participants
  belongs_to :user

  validates :user_id, uniqueness: { scope: :conversation_id }
end

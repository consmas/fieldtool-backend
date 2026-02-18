class ChatConversation < ApplicationRecord
  enum :kind, { direct: 0, group: 1 }, prefix: true

  belongs_to :created_by, class_name: "User", optional: true
  has_many :participants, class_name: "ChatConversationParticipant", foreign_key: :conversation_id, dependent: :destroy, inverse_of: :conversation
  has_many :users, through: :participants
  has_many :messages, class_name: "ChatConversationMessage", foreign_key: :conversation_id, dependent: :destroy, inverse_of: :conversation

  validates :kind, presence: true

  def participant?(user)
    return false if user.blank?

    participants.exists?(user_id: user.id)
  end

  def touch_last_message_at!(time = Time.current)
    update_column(:last_message_at, time)
  end
end

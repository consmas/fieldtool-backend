class ChatMessage < ApplicationRecord
  belongs_to :chat_thread, inverse_of: :messages
  belongs_to :sender, class_name: "User"

  validates :body, presence: true, length: { maximum: 2000 }
  validate :sender_must_be_thread_participant

  after_create_commit :touch_thread_last_message_at

  private

  def sender_must_be_thread_participant
    return if chat_thread&.participant?(sender)

    errors.add(:sender, "is not allowed in this chat")
  end

  def touch_thread_last_message_at
    chat_thread.update_column(:last_message_at, created_at)
  end
end

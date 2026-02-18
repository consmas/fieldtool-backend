class ChatThread < ApplicationRecord
  belongs_to :trip
  belongs_to :driver, class_name: "User"
  belongs_to :dispatcher, class_name: "User", optional: true
  has_many :messages, class_name: "ChatMessage", dependent: :destroy, inverse_of: :chat_thread

  validates :trip_id, uniqueness: true

  def participant?(user)
    return false if user.blank?
    return true if user.admin? || user.supervisor?
    return true if driver_id == user.id

    dispatcher_id == user.id
  end
end

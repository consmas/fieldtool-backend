class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  enum :role, {
    driver: 0,
    dispatcher: 1,
    supervisor: 2,
    admin: 3
  }

  has_many :assigned_trips, class_name: "Trip", foreign_key: :driver_id, inverse_of: :driver, dependent: :nullify
  has_many :created_trip_events, class_name: "TripEvent", foreign_key: :created_by_id, inverse_of: :created_by, dependent: :nullify
  has_many :uploaded_evidence, class_name: "Evidence", foreign_key: :uploaded_by_id, inverse_of: :uploaded_by, dependent: :nullify
  has_many :recorded_location_pings, class_name: "LocationPing", foreign_key: :recorded_by_id, inverse_of: :recorded_by, dependent: :nullify
  has_many :pre_trip_inspections, foreign_key: :captured_by_id, inverse_of: :captured_by, dependent: :nullify
  has_many :driver_chat_threads, class_name: "ChatThread", foreign_key: :driver_id, dependent: :nullify, inverse_of: :driver
  has_many :dispatcher_chat_threads, class_name: "ChatThread", foreign_key: :dispatcher_id, dependent: :nullify, inverse_of: :dispatcher
  has_many :chat_messages, foreign_key: :sender_id, dependent: :nullify, inverse_of: :sender
  has_many :chat_conversation_participants, dependent: :destroy, inverse_of: :user
  has_many :chat_conversations, through: :chat_conversation_participants
  has_many :sent_chat_conversation_messages, class_name: "ChatConversationMessage", foreign_key: :sender_id, dependent: :nullify, inverse_of: :sender

  validates :role, presence: true
end

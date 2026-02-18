class CreateChatConversationParticipants < ActiveRecord::Migration[8.0]
  def change
    create_table :chat_conversation_participants do |t|
      t.references :conversation, null: false, foreign_key: { to_table: :chat_conversations }
      t.references :user, null: false, foreign_key: true
      t.datetime :last_read_at

      t.timestamps
    end

    add_index :chat_conversation_participants, [:conversation_id, :user_id], unique: true, name: "idx_chat_conversation_participants_unique"
    add_index :chat_conversation_participants, :last_read_at
  end
end

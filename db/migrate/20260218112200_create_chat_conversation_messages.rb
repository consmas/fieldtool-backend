class CreateChatConversationMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :chat_conversation_messages do |t|
      t.references :conversation, null: false, foreign_key: { to_table: :chat_conversations }
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.text :body, null: false

      t.timestamps
    end

    add_index :chat_conversation_messages, [:conversation_id, :created_at], name: "idx_chat_conversation_messages_timeline"
  end
end

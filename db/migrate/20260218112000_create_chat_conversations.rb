class CreateChatConversations < ActiveRecord::Migration[8.0]
  def change
    create_table :chat_conversations do |t|
      t.integer :kind, null: false, default: 0
      t.string :title
      t.references :created_by, foreign_key: { to_table: :users }
      t.datetime :last_message_at

      t.timestamps
    end

    add_index :chat_conversations, :kind
    add_index :chat_conversations, :last_message_at
  end
end

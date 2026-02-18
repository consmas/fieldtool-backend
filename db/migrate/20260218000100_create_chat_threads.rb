class CreateChatThreads < ActiveRecord::Migration[8.0]
  def change
    create_table :chat_threads do |t|
      t.references :trip, null: false, foreign_key: true, index: { unique: true }
      t.references :driver, null: false, foreign_key: { to_table: :users }
      t.references :dispatcher, foreign_key: { to_table: :users }
      t.datetime :last_message_at

      t.timestamps
    end
  end
end

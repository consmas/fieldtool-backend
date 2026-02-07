class AddPhoneToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :phone_number, :string
    add_index :users, :phone_number
  end
end

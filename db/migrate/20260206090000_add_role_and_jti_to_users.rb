class AddRoleAndJtiToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :name, :string
    add_column :users, :role, :integer, null: false, default: 0
    add_column :users, :jti, :string, null: false, default: ""
    add_index :users, :jti, unique: true
  end
end

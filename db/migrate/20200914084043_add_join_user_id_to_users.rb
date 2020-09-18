class AddJoinUserIdToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :join_user_id, :integer
  end
end

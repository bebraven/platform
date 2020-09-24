class AddLinkedInAuthorizationToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :linked_in_access_token, :string
    add_column :users, :linked_in_state, :string
  end
end

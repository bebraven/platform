class RemoveAdminFromUser < ActiveRecord::Migration[6.0]
  def change
    # Migrate all current admins to new role system.
    User.where(admin: true).each do |user|
      user.add_role :admin
    end

    remove_column :users, :admin, :boolean
  end
end

class RenameUsersCanvasId < ActiveRecord::Migration[6.0]
  def change
    rename_column :users, :canvas_id, :canvas_user_id
  end
end

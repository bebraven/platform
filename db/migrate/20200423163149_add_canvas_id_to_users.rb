class AddCanvasIdToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :canvas_id, :integer
    add_index :users, :canvas_id, unique: true
  end
end

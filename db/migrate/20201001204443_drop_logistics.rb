class DropLogistics < ActiveRecord::Migration[6.0]
  def change
    remove_column :sections, :logistic_id
    drop_table :logistics
  end
end

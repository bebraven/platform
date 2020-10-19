class DropOldUnusedTables < ActiveRecord::Migration[6.0]
  def change
    drop_table :industries
    drop_table :interests
    drop_table :locations
    drop_table :majors
    drop_table :postal_codes
  end
end

class DropMoreTables < ActiveRecord::Migration[6.0]
  def change
    drop_table :addresses
    drop_table :phones
    drop_table :emails
  end
end

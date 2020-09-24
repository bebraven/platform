class RemoveOrganization < ActiveRecord::Migration[6.0]
  def change
    remove_column :base_courses, :organization_id, :bigint
    drop_table :organizations, {}
  end
end

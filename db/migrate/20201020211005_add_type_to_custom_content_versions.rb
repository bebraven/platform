class AddTypeToCustomContentVersions < ActiveRecord::Migration[6.0]
  def change
    add_column :custom_content_versions, :type, :string
  end
end

class AddUniqueIndexToBcccv < ActiveRecord::Migration[6.0]
  def change
    add_index :base_course_custom_content_versions, [:base_course_id, :custom_content_version_id], unique: true, name: 'index_bcccv_unique_version_ids'
  end
end

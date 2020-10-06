class RenameCourseContentIdCustomContentId < ActiveRecord::Migration[6.0]
  def change
    rename_column :custom_content_versions, :course_content_id, :custom_content_id
  end
end

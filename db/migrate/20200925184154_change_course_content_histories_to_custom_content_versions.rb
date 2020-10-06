class ChangeCourseContentHistoriesToCustomContentVersions < ActiveRecord::Migration[6.0]
  def change
    rename_table :course_content_histories, :custom_content_versions
  end
end

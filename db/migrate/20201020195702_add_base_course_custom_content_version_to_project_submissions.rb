class AddBaseCourseCustomContentVersionToProjectSubmissions < ActiveRecord::Migration[6.0]
  def change
    ProjectSubmission.delete_all
    add_reference :project_submissions, :base_course_custom_content_version, null: false, foreign_key: true, index: { name: 'index_submissions_on_base_course_custom_content_version_id' }
  end
end

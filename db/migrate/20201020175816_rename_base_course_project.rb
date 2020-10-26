class RenameBaseCourseProject < ActiveRecord::Migration[6.0]
  def change
    create_table :base_course_custom_content_versions do |t|
      t.references :base_course, null: false, foreign_key: true
      t.references :custom_content_version, null: false, foreign_key: true, index: { name: 'index_base_course_custom_content_versions_on_version_id' }
      t.integer :canvas_assignment_id
    end
  end
end

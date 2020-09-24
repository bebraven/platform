class RenameProgramResourceToCourseResource < ActiveRecord::Migration[6.0]
  def change
    rename_column :base_courses, :program_resource_id, :course_resource_id
    rename_table :program_resources, :course_resources
  end
end

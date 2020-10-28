class DropProjects < ActiveRecord::Migration[6.0]
  def change
    remove_reference :rubrics, :project
    remove_reference :project_submissions, :project
    drop_table :base_course_projects, {}
    drop_table :projects
  end
end

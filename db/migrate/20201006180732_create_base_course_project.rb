class CreateBaseCourseProject < ActiveRecord::Migration[6.0]
  def change
    create_table :base_course_projects do |t|
      t.references :base_course, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.integer :canvas_assignment_id
    end
  end
end

class RenameProgramRefsToBaseCourse < ActiveRecord::Migration[6.0]
  def change
    rename_column :grade_categories, :program_id, :base_course_id

    remove_index :logistics, name: :index_logistics_on_day_of_week_and_time_of_day_and_program_id
    rename_column :logistics, :program_id, :base_course_id
    add_index :logistics, [:day_of_week, :time_of_day, :base_course_id], unique: true, name: :index_logistics_on_day_time_course

    rename_column :program_memberships, :program_id, :base_course_id
    rename_column :sections, :program_id, :base_course_id
  end
end

class ChangeProjectsColumnsNullable < ActiveRecord::Migration[6.0]
  def change
    change_column_null :projects, :name, true
    change_column_null :projects, :points_possible, true
    change_column_null :projects, :percent_of_grade_category, true
    change_column_null :projects, :grades_muted, true
    change_column_null :projects, :grades_published_at, true

    remove_reference :projects, :grade_category
    add_reference :projects, :grade_category, foreign_key: true, index: true, null: true
  end
end

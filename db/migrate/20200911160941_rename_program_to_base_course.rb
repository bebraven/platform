class RenameProgramToBaseCourse < ActiveRecord::Migration[6.0]
  def change
    rename_table :programs, :base_courses
  end
end

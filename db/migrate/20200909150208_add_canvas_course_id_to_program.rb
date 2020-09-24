class AddCanvasCourseIdToProgram < ActiveRecord::Migration[6.0]
  def change
    add_column :programs, :canvas_course_id, :integer
  end
end

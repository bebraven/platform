class CreateAttendanceEvents < ActiveRecord::Migration[6.0]
  def change
    create_table :attendance_events do |t|
      t.string :name
      t.integer :canvas_assignment_id
      t.integer :canvas_course_id

      t.timestamps

      t.index :canvas_course_id
      t.index [:canvas_course_id, :canvas_assignment_id], unique: true, name: 'index_attendance_events_on_course_id_and_assignment_id'
    end
  end
end

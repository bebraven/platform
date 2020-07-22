class CreateLessonContents < ActiveRecord::Migration[6.0]
  def change
    create_table :lesson_contents do |t|

      t.timestamps
    end
  end
end

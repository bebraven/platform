class CreateLessonInteractions < ActiveRecord::Migration[6.0]
  def change
    create_table :lesson_interactions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :activity_id, null: false
      t.boolean :success
      t.integer :progress
      t.string :verb, null: false
      t.integer :canvas_course_id, null: false
      t.integer :canvas_assignment_id, null: false
      t.boolean :new, default: true, null: false

      t.timestamps
    end

    add_index(:lesson_interactions, [:new, :user_id, :activity_id, :verb], :name => 'index_lesson_interactions_1')
  end
end

class AddMetadataToLessonContent < ActiveRecord::Migration[6.0]
  def change
    add_column :lesson_contents, :activity_id, :string
    add_column :lesson_contents, :quiz_questions, :integer
    add_index :lesson_contents, [:activity_id]
  end
end

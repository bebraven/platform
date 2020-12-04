class CreateProjectSubmissionAnswers < ActiveRecord::Migration[6.0]
  def change
    create_table :project_submission_answers do |t|
      t.references :project_submission, null: false, foreign_key: true
      t.string :input_name
      t.text :input_value
    end

    add_index :project_submission_answers,
      [:project_submission_id, :input_name],
      unique: true,
      name: 'index_project_submission_answers_unique_1'
  end
end

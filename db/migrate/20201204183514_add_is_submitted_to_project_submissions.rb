class AddIsSubmittedToProjectSubmissions < ActiveRecord::Migration[6.0]
  def change
    add_column :project_submissions, :is_submitted, :boolean
  end
end

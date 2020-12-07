class AddUniquenessColumnToProjectSubmissions < ActiveRecord::Migration[6.0]
  def change
    # Nullable column with a default, so we can create a conditional, db-level
    # uniqueness constraint by taking advantage of the fact that null values are
    # treated as unique from other null values. See also app/models/project_submission.rb.
    # Note the default of "1" is an arbitrarily chosen non-null value.
    # https://stackoverflow.com/a/18293770/12432170
    add_column :project_submissions, :uniqueness_condition, :integer, default: 1

    # Migrate existing records. If this migration still fails at the add_index step,
    # it means you have multiple is_submitted:false submissions for the same user/project,
    # which is *not valid*, and you should correct that manually and re-run this
    # migration.
    ProjectSubmission.where(is_submitted: true).each do |ps|
      ps.update!(uniqueness_condition: nil)
    end

    add_index :project_submissions,
      [:user_id, :course_custom_content_id, :is_submitted, :uniqueness_condition],
      unique: true,
      name: 'index_project_submissions_unique_1'
  end
end

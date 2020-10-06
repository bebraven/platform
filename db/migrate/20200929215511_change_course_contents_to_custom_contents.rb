class ChangeCourseContentsToCustomContents < ActiveRecord::Migration[6.0]
  def change
    rename_table :course_contents, :custom_contents
  end
end

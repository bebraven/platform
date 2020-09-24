class RemoveBaseCourseTerm < ActiveRecord::Migration[6.0]
  def change
    remove_column :base_courses, :term, :string
  end
end

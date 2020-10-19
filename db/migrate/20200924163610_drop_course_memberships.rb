class DropCourseMemberships < ActiveRecord::Migration[6.0]
  def change
    drop_table :course_memberships
  end
end

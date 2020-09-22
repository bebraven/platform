class AddWaiversSignedAtToCourseMemberships < ActiveRecord::Migration[6.0]
  def change
    add_column :course_memberships, :waivers_signed_at, :datetime
    add_index :course_memberships, [:user_id, :base_course_id]
  end
end

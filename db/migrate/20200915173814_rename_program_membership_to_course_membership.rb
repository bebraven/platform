class RenameProgramMembershipToCourseMembership < ActiveRecord::Migration[6.0]
  def change
    rename_table :program_memberships, :course_memberships
  end
end

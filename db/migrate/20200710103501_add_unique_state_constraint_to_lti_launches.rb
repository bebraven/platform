class AddUniqueStateConstraintToLtiLaunches < ActiveRecord::Migration[6.0]
  def change
    # Have to truncate the table, or the migration will crash on duplicate states.
    LtiLaunch.delete_all
    remove_index :lti_launches, :state
    add_index :lti_launches, :state, unique: true
  end
end

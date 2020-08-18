class AddSessionlessToLtiLaunches < ActiveRecord::Migration[6.0]
  def change
    add_column :lti_launches, :sessionless, :boolean, default: false
  end
end

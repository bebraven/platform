class RemoveNullNonceConstraintFromLtiLaunches < ActiveRecord::Migration[6.0]
  def change
    change_column_null :lti_launches, :nonce, true
  end
end

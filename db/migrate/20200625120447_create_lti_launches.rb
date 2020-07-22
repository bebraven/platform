# Stores info about an LTI launch so we can access that stuff in future calls
# in the context of that launch
class CreateLtiLaunches < ActiveRecord::Migration[6.0]
  def change
    create_table :lti_launches do |t|
      t.string :client_id, null: false
      t.string :login_hint, null: false
      t.text :lti_message_hint                 # This is an optional param in a launch, but Canvas does send it
      t.string :target_link_uri, null: false
      t.string :nonce, null: false
      t.string :state, null: false
      t.index :state                           # This is what we use to identify the launch session and look up the launch info
      t.text :id_token_payload
      
      t.timestamps
    end
  end
end

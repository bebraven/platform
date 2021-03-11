class CreateChampions < ActiveRecord::Migration[6.0]
  def change
    create_table :champions do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :phone
      t.string :linkedin_url
      t.boolean :braven_fellow
      t.boolean :braven_lc
      t.boolean :willing_to_be_contacted
      t.string :industries, array: true, default: []
      t.string :studies, array: true, default: []
      t.string :region
      t.string :access_token
      t.string :company
      t.string :job_title
      t.string :salesforce_id

      t.timestamps
    end
  end
end

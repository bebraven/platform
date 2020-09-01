class CreateFormKeyValues < ActiveRecord::Migration[6.0]
  def change
    create_table :form_key_values do |t|
      t.references :user, null: false, foreign_key: true
      t.string :key, null: false
      t.string :value

      t.timestamps
    end

    add_index :form_key_values, [:user_id, :key], unique: true
  end
end

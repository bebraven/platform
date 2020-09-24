class CreateProgramResources < ActiveRecord::Migration[6.0]
  def change
    create_table :program_resources do |t|
      t.string :name

      t.timestamps
    end
  end
end

class AddResourceToProgram < ActiveRecord::Migration[6.0]
  def change
    add_reference :programs, :program_resource, null: true, foreign_key: true
  end
end

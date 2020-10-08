class AddCustomContentVersionToProjects < ActiveRecord::Migration[6.0]
  def change
      add_reference :projects, :custom_content_version, foreign_key: true, index: true, null: true
  end
end

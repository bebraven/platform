class AddCanvasSectionIdToSections < ActiveRecord::Migration[6.0]
  def change
    add_column :sections, :canvas_section_id, :integer
  end
end

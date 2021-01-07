# Complete HAX!! DO NOT MERGE to highlander codebase. In old code,
# we don't actually use the Sections, we just need to have one there.
# In multiple courses we may use the same section name, but everything uses
# the 'Production Dummy' course which violates this constraint.

class RemoveCorrectUniqueIndexFromSections < ActiveRecord::Migration[6.0]
  def change
    # This undoes 20210106190034_remove_unique_index_from_user_sections.rb
    # We removed the wrong index. Put it back and remove the correct one below.
    add_index :user_sections, [:user_id, :section_id], unique: true
    remove_index :sections, name: :index_sections_on_name_and_base_course_id
  end 
end

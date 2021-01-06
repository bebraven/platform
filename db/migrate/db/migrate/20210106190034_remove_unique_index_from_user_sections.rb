# Complete HAX!! DO NOT MERGE to highlander codebase. In old code,
# we don't actually use the UserSections, we just need to have one there.
# In multiple courses we may use the same section name, but everything uses
# the 'Production Dummy' course which violates this constraint.

class RemoveUniqueIndexFromUserSections < ActiveRecord::Migration[6.0]
  def change
    remove_index :user_sections, name: :index_user_sections_on_user_id_and_section_id
  end 
end

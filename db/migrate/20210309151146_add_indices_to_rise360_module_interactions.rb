class AddIndicesToRise360ModuleInteractions < ActiveRecord::Migration[6.0]
  def change
    # Add indices to speed up our specific queries.
    add_index :rise360_module_interactions,
      [:canvas_course_id, :canvas_assignment_id],
      name: 'index_rise360_module_interactions_on_course_assignment'
    add_index :rise360_module_interactions,
      [:canvas_assignment_id, :user_id, :verb],
      name: 'index_rise360_module_interactions_on_assignment_user_verb'
    add_index :rise360_module_interactions,
      [:new, :canvas_course_id, :canvas_assignment_id, :user_id],
      name: 'index_rise360_module_interactions_on_new_course_assignment_user'
    add_index :rise360_module_interactions, :canvas_assignment_id

    # Remove indices for queries we no longer use.
    remove_index :rise360_module_interactions,
      column: [:new, :user_id, :activity_id, :verb],
      name: 'index_lesson_interactions_1'
    remove_index :rise360_module_interactions,
      column: [:user_id, :canvas_assignment_id],
      name: 'index_rise360_module_interactions_on_user_id_and_assignment_id'
  end
end

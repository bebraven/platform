require 'rails_helper'

RSpec.describe LessonInteraction, type: :model do

  # Associations
  it { should belong_to :user }

  # Validations
  it { should validate_presence_of :user }
  it { should validate_presence_of :activity_id }
  it { should validate_presence_of :verb }
  it { should validate_presence_of :canvas_course_id }
  it { should validate_presence_of :canvas_assignment_id }
end

require 'rails_helper'

RSpec.describe CourseResource, type: :model do
  it { should have_many :courses }
  it { should have_many :course_templates }
  it { should validate_presence_of :name }
end

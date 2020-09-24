require 'rails_helper'

RSpec.describe CourseTemplate, type: :model do
  include BaseCoursesHelper

  let(:course_template) { build(:course_template) }

  describe '#save' do
    context 'when course_template name has extra whitespace' do
      it 'strips away the whitespace in name' do
        name_with_whitespace = "  #{course_template.name}  "
        course_template.name = name_with_whitespace
        course_template.save!
        expect(course_template.name).to eq(name_with_whitespace.strip)
      end
    end
  end

  it 'has a humanized_type of Course Template' do
    expect(humanized_type(course_template)).to eq('Course Template')
  end
  
end

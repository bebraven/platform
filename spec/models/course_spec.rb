require 'rails_helper'

RSpec.describe Course, type: :model do
  include BaseCoursesHelper

  let(:course) { build(:course) }

  describe '#save' do
    context 'when course name has extra whitespace' do
      it 'strips away the whitespace in name' do
        name_with_whitespace = "  #{course.name}  "
        course.name = name_with_whitespace
        course.save!
        expect(course.name).to eq(name_with_whitespace.strip)
      end
    end
  end

  it 'has a humanized_type of Course' do
    expect(humanized_type(course)).to eq('Course')
  end
  
end

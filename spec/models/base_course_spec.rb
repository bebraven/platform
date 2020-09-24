require 'rails_helper'

RSpec.describe BaseCourse, type: :model do

  let(:course_name) { 'Course Or Template Name' }
  let(:base_course) { build :base_course, name: course_name}
  
  describe '#valid?' do
    subject { base_course }

    context 'when course name is empty' do
      let(:course_name) { '' }
      it { is_expected.to_not be_valid }
    end
  end

  describe '#to_show' do
    subject { base_course.to_show }
    
    it { should eq({'name' => course_name}) }
  end
end

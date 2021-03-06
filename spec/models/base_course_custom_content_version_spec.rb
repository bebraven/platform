require 'rails_helper'

RSpec.describe BaseCourseCustomContentVersion, type: :model do

  let(:course) { create :course }
  let(:project) { create :project }
  let(:project_version) { create :project_version, custom_content: project }
  let(:base_course_custom_content_version) { create :base_course_custom_content_version, base_course: course, custom_content_version: project_version }
  
  describe '#valid?' do
    subject { base_course_custom_content_version }

    context 'when valid attributes' do
      it { is_expected.to be_valid }
    end
  end
end

require 'rails_helper'

RSpec.describe CustomContent, type: :model do
  let(:course) { create :course }
  let(:project) { create :project }
  let(:project_version) { create :project_version, custom_content: project }
  let!(:base_course_custom_content_version) { create :base_course_custom_content_version, base_course: course, custom_content_version: project_version }

  describe '#base_courses' do
    subject { project.base_courses.first }

    it { should eq(course) }
  end

  describe '#courses' do
    subject { project.courses.first }

    it { should eq(course) }
  end

  describe '#course_templates' do
    subject { project.course_templates.first }

    it { should eq(nil) }
  end

end

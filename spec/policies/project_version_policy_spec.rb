require 'rails_helper'

RSpec.describe ProjectVersionPolicy, type: :policy do
  let(:user) { create(:registered_user) }
  let(:course) { create(:course) }
  let(:project) { create(:project) }
  let(:project_version) { create(:project_version, custom_content: project) }
  let(:section) { create(:section, base_course_id: course.id) }
  let(:base_course_custom_content_version) { create(:base_course_custom_content_version, base_course: course, custom_content_version: project_version) }

  subject { described_class }

  permissions :show? do
    it "allows any admin user to show a given project version" do
      user.add_role :admin
      expect(subject).to permit user, project_version
    end

    it "allows a non-admin user to show a project version attached to a course where this user is enrolled" do
      base_course_custom_content_version
      user.add_role RoleConstants::STUDENT_ENROLLMENT, section
      expect(subject).to permit user, project_version
    end

    it "disallows any user when no project version is passed in" do
      expect(subject).not_to permit user
    end

    it "disallows non-admin users not enrolled in a course attached to the project version" do
      expect(subject).not_to permit user, project_version
    end
  end
end

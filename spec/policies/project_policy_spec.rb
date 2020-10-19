require 'rails_helper'

RSpec.describe ProjectPolicy, type: :policy do
  let(:user) { create(:registered_user) }
  let(:course) { create(:course) }
  let(:project) { create(:project) }
  let(:course_project) { create(:course_project, base_course_id: course.id, project_id: project.id) }
  let(:section) { create(:section, base_course_id: course.id) }

  subject { described_class }

  permissions :show? do
    it "allows any admin user to show a given project" do
      user.add_role :admin
      expect(subject).to permit user, project
    end

    it "allows a non-admin user to show a project attached to a course where this user is enrolled" do
      course_project
      user.add_role RoleConstants::STUDENT_ENROLLMENT, section
      expect(subject).to permit user, project
    end

    it "disallows any user when no project is passed in" do
      expect(subject).not_to permit user
    end

    it "disallows non-admin users not enrolled in a course attached to the project" do
      expect(subject).not_to permit user, project
    end
  end
end

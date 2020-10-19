require 'rails_helper'

RSpec.describe ProjectSubmissionPolicy, type: :policy do
  let(:user) { create(:registered_user) }
  let(:course) { create(:course) }
  let(:project) { create(:project) }
  let(:course_project) { create(:course_project, base_course_id: course.id, project_id: project.id) }
  let(:section) { create(:section, base_course_id: course.id) }
  let(:project_submission) { create(:project_submission, project_id: project.id) }

  subject { described_class }

  permissions :show? do
    it "allows any admin user to show a given project submission" do
      user.add_role :admin
      expect(subject).to permit user, project_submission
    end

    it "allows a non-admin user to show a project submission attached to a course where this user is enrolled" do
      course_project
      user.add_role RoleConstants::STUDENT_ENROLLMENT, section
      expect(subject).to permit user, project_submission
    end

    it "disallows non-admin users not enrolled in a course attached to the project" do
      expect(subject).not_to permit user, project_submission
    end
  end

  permissions :new? do
    it "allows any admin user to show a given project submission" do
      user.add_role :admin
      expect(subject).to permit user, project_submission
    end

    it "allows a non-admin user to show a project submission attached to a course where this user is enrolled" do
      course_project
      user.add_role RoleConstants::STUDENT_ENROLLMENT, section
      expect(subject).to permit user, project_submission
    end

    it "disallows non-admin users not enrolled in a course attached to the project" do
      expect(subject).not_to permit user, project_submission
    end
  end

  permissions :create? do
    it "allows any admin user to show a given project submission" do
      user.add_role :admin
      expect(subject).to permit user, project_submission
    end

    it "allows a non-admin user to show a project submission attached to a course where this user is enrolled" do
      course_project
      user.add_role RoleConstants::STUDENT_ENROLLMENT, section
      expect(subject).to permit user, project_submission
    end

    it "disallows non-admin users not enrolled in a course attached to the project" do
      expect(subject).not_to permit user, project_submission
    end
  end
end

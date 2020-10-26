require 'rails_helper'

RSpec.describe ProjectSubmissionPolicy, type: :policy do
  let(:user) { create(:registered_user) }
  let(:course) { create(:course) }
  let(:project_version) { create(:project_version) }
  let(:section) { create(:section, course: course) }
  let(:project_submission) { create(:project_submission, project_version: project_version) }
  let(:base_course_custom_content_version) { create(:base_course_custom_content_version, base_course: course, custom_content_version: project_version) }

  subject { described_class }

  permissions :show? do
    it "allows any admin user to show a given project submission" do
      user.add_role :admin
      expect(subject).to permit user, project_submission
    end

    it "allows a non-admin user to show a project submission attached to a course where this user is enrolled" do
      base_course_custom_content_version
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
      base_course_custom_content_version
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
      base_course_custom_content_version
      user.add_role RoleConstants::STUDENT_ENROLLMENT, section
      expect(subject).to permit user, project_submission
    end

    it "disallows non-admin users not enrolled in a course attached to the project" do
      expect(subject).not_to permit user, project_submission
    end
  end
end

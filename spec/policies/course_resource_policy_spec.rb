require 'rails_helper'

RSpec.describe CourseResourcePolicy, type: :policy do
  let(:user) { create(:registered_user) }

  subject { described_class }

  permissions :lti_show? do
    it "allows all logged-in users" do
      expect(subject).to permit(user)
    end

    it "disallows anonymous users" do
      expect(subject).not_to permit(nil)
    end
  end

  permissions :create? do
    it "disallows non-admin users" do
      expect(subject).not_to permit(user)
    end

    it "allows admin users" do
      user.add_role :admin
      expect(subject).to permit(user)
    end
  end

  permissions :new? do
    it "disallows non-admin users" do
      expect(subject).not_to permit(user)
    end

    it "allows admin users" do
      user.add_role :admin
      expect(subject).to permit(user)
    end
  end
end

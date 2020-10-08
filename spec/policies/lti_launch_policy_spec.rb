require 'rails_helper'

RSpec.describe LtiLaunchPolicy, type: :policy do
  let(:user) { create(:registered_user) }
  let(:canvas_user) { create(:fellow_user) }
  let(:record) { create(:lti_launch_assignment, canvas_user_id: canvas_user.canvas_user_id) }

  subject { described_class }

  permissions :login? do
    it "allows all logged-in users" do
      expect(subject).to permit(user)
    end

    it "allows anonymous users" do
      expect(subject).to permit(nil)
    end
  end

  permissions :launch? do
    it "allows all logged-in users" do
      expect(subject).to permit(user)
    end

    it "disallows anonymous users" do
      expect(subject).not_to permit(nil)
    end
    
    it "allows nil current_user if the record has an attached user" do
      expect(subject).to permit(nil, record)
    end
  end

  permissions :new? do
    it "allows admin users" do
      user.add_role :admin
      expect(subject).to permit(user)
    end

    it "disallows non-admin users" do
      expect(subject).not_to permit(user)
    end
  end

  permissions :create? do
    it "allows admin users" do
      user.add_role :admin
      expect(subject).to permit(user)
    end

    it "disallows non-admin users" do
      expect(subject).not_to permit(user)
    end
  end
end

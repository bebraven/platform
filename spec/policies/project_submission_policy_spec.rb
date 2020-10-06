require 'rails_helper'

RSpec.describe ProjectSubmissionPolicy, type: :policy do
  let(:user) { create(:registered_user) }

  subject { described_class }

  permissions :create? do
    it "allows any signed-in user to create a project submission" do
      expect(subject).to permit user
    end

    it "disallows anonymous users from creating a project submission" do
      expect(subject).not_to permit nil
    end
  end
end

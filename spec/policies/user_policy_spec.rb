require 'rails_helper'

RSpec.describe UserPolicy, type: :policy do
  let(:user) { create(:registered_user) }

  subject { described_class }

  permissions :confirm? do
    it "allows admin users" do
      user.add_role :admin
      expect(subject).to permit(user)
    end

    it "disallows non-admin users" do
      expect(subject).not_to permit(user)
    end
  end
end

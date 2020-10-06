require 'rails_helper'

RSpec.describe LinkedInAuthorizationPolicy, type: :policy do
  let(:user) { create(:registered_user) }

  subject { described_class }

  permissions :login? do
    it "allows any user to see LinkedIn sign-in button" do
      expect(subject).to permit(user)
    end
  end

  permissions :launch? do
    it "allows any user to launch LinkedIn authorization flow" do
      expect(subject).to permit(user)
    end
  end

  permissions :oauth_redirect? do
    it "allows any user to redirect after going through LinkedIn flow" do
      expect(subject).to permit(user)
    end
  end
end

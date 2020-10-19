require 'rails_helper'

RSpec.describe HoneycombJsPolicy, type: :policy do
  let(:user) { create(:registered_user) }

  subject { described_class }

  permissions :send_span? do
    it "disallows anonymous users" do
      expect(subject).not_to permit nil
    end

    it "allows any logged-in user" do
      expect(subject).to permit user
    end
  end
end

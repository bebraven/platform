require 'rails_helper'

RSpec.describe KeypairPolicy, type: :policy do
  let(:user) { create(:registered_user) }

  subject { described_class }

  permissions :index? do
    it "allows access without login" do
      expect(subject).to permit nil
    end

    it "allows access to any user" do
      expect(subject).to permit user
    end
  end
end

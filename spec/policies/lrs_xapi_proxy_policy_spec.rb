require 'rails_helper'

RSpec.describe LrsXapiProxyPolicy, type: :policy do
  subject { described_class }

  permissions :xAPI_read? do
    it "allows user to read their own data" do
      user = create(:registered_user)
      expect(subject).to permit(user, user)
    end

    it "disallows user to read another arbitrary user's data" do
      user1 = create(:registered_user)
      user2 = create(:registered_user)
      expect(subject).not_to permit(user1, user2)
    end

    it "disallows user to read data for a user in their section" do
      user1 = create(:registered_user)
      user2 = create(:registered_user)
      section = create(:section)
      user1.add_role RoleConstants::STUDENT_ENROLLMENT, section
      user2.add_role RoleConstants::STUDENT_ENROLLMENT, section
      expect(subject).not_to permit(user1, user2)
    end

    it "allows TA to read data for a user in their section" do
      user1 = create(:registered_user)
      user2 = create(:registered_user)
      section = create(:section)
      user1.add_role RoleConstants::TA_ENROLLMENT, section
      user2.add_role RoleConstants::STUDENT_ENROLLMENT, section
      expect(subject).to permit(user1, user2)
    end

    it "disallows TA to read data for a user in another section" do
      user1 = create(:registered_user)
      user2 = create(:registered_user)
      section1 = create(:section)
      section2 = create(:section)
      user1.add_role RoleConstants::TA_ENROLLMENT, section1
      user2.add_role RoleConstants::STUDENT_ENROLLMENT, section2
      expect(subject).not_to permit(user1, user2)
    end
  end

  permissions :xAPI_write? do
    it "allows user to write their own data" do
      user = create(:registered_user)
      expect(subject).to permit(user, user)
    end

    it "disallows user to read another arbitrary user's data" do
      user1 = create(:registered_user)
      user2 = create(:registered_user)
      expect(subject).not_to permit(user1, user2)
    end
  end
end

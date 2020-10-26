require 'rails_helper'

RSpec.describe "custom_content_versions/show", type: :view do
  let(:custom_content_version) { create(:project_version) }
  let(:user) { create(:admin_user) }

  before(:each) do
    assign(:custom_content_version, custom_content_version)
    assign(:user, user)
    assign(:custom_content, custom_content_version.custom_content)
  end

  it "renders bz-assignment" do
    render
    expect(rendered).to match(/<div class="bz-assignment">/)
  end
end

require 'rails_helper'

RSpec.describe "custom_content_versions/show", type: :view do
  let(:custom_content) { create(:custom_content) }
  let(:custom_content_assignment) { create(:custom_content_assignment) }
  let(:user) { create(:admin_user) }

  before(:each) do
    assign(:custom_content, custom_content)
    assign(:user, user)
    assign(:custom_content_version, custom_content_assignment)
  end

  it "renders bz-assignment" do
    render
    expect(rendered).to match(/<div class="bz-assignment">/)
  end

  # TODO: actually write specs for this view. It's a TA view of the submission populated with
  # student answers
end

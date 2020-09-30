require 'rails_helper'

RSpec.describe "custom_content_versions/show", type: :view do
  let(:course_content) { create(:course_content) }
  let(:course_content_assignment) { create(:course_content_assignment) }
  let(:user) { create(:admin_user) }

  before(:each) do
    assign(:course_content, course_content)
    assign(:user, user)
    assign(:custom_content_version, course_content_assignment)
  end

  it "renders bz-assignment" do
    render
    expect(rendered).to match(/<div class="bz-assignment">/)
  end

  # TODO: actually write specs for this view. It's a TA view of the submission populated with
  # student answers
end

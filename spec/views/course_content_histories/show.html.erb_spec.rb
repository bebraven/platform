require 'rails_helper'

RSpec.describe "course_content_histories/show", type: :view do
  let(:course_content) { create(:course_content) }
  let(:user) { create(:admin_user) }

  before(:each) do
    assign(:course_content, course_content)
    assign(:user, user)

    assign(:course_content_history, CourseContentHistory.create!(
      :course_content_id => course_content.id,
      :user => user,
      :title => "Title",
      :body => "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(Regexp.new(course_content.id.to_s))
    expect(rendered).to match(/Title/)
    expect(rendered).to match(/MyText/)
  end
end

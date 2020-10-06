require 'rails_helper'

RSpec.describe "custom_contents/edit", type: :view do
  before(:each) do
    @custom_content = assign(:custom_content, CustomContent.create!(
      :title => "MyString",
      :body => "MyText",
      :content_type => "MyText"
    ))
  end

  it "renders the edit custom_content form" do
    render

    assert_select "form[action=?][method=?]", custom_content_path(@custom_content), "post"
  end
end

require 'rails_helper'

RSpec.describe "custom_contents/new", type: :view do
  before(:each) do
    assign(:custom_content, CustomContent.new(
      :title => "MyString",
      :body => "MyText",
      :content_type => "MyText"
    ))
  end

  it "renders new custom_content form" do
    render

    assert_select "form[action=?][method=?]", custom_contents_path, "post"
  end
end

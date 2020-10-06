require 'rails_helper'

RSpec.describe "custom_contents/index", type: :view do
  before(:each) do
    assign(:custom_contents, [
      CustomContent.create!(
        :title => "Title",
        :body => "MyBody",
        :content_type => "MyCustomContentType"
      ),
      CustomContent.create!(
        :title => "Title",
        :body => "MyBody",
        :content_type => "MyCustomContentType"
      )
    ])
  end

  it "renders a list of custom_contents" do
    render
    assert_select "ul>li", :text => /Title/, :count => 2
  end
end

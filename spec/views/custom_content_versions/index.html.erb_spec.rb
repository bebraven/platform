require 'rails_helper'

RSpec.describe "custom_content_versions/index", type: :view do
  let(:custom_content) { create(:custom_content) }
  let(:user) { create(:admin_user) }

  before(:each) do
    assign(:custom_content, custom_content)
    assign(:user, user)
    assign(:custom_content_versions, [
      CustomContentVersion.create!(
        :custom_content_id => custom_content.id,
        :user => user,
        :title => "Title",
        :body => "MyText"
      ),
      CustomContentVersion.create!(
        :custom_content_id => custom_content.id,
        :user => user,
        :title => "Title",
        :body => "MyText"
      )
    ])
  end

  it "renders a list of :" do
    render
    assert_select "tr>td", :count => 10
    assert_select "tr>td", :text => "Title".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
  end
end

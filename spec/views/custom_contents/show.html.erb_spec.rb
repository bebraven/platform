require 'rails_helper'

RSpec.describe "custom_contents/show", type: :view do
  before(:each) do
    assign(:custom_content, CustomContent.create!(
      :title => "Title",
      :body => "<p>MyText</p>",
    ))
  end

  it "renders HTML" do
    render
    expect(rendered).to match(/<p>MyText<\/p>/)
  end

  it "adds appropriate div class for assignment" do
    assign(:custom_content, CustomContent.create!(
      :title => "Title",
      :body => "<p>MyText</p>",
    ))
    render
    expect(rendered).to match(/<div class="bv-custom-content-container">/)
  end
end

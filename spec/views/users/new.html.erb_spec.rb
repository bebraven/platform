require 'rails_helper'

RSpec.describe "users/new", type: :view do
  before(:each) do
    assign(:user, User.new(
      :first_name => "Test",
      :last_name => "User",
      :email => "test.user@example.com",
      :password => 'test1234',
    ))
  end

  it "renders the form with the correct path" do
    render
    assert_select "form[action=?][method=?]", admin_users_path, "post"
  end
end

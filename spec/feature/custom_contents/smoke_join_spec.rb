require "rails_helper"
require "capybara_helper"

include ERB::Util
include Rack::Utils

if ENV['BZ_AUTH_SERVER'] # Only run these specs if on a server with Join authentication enabled

RSpec.describe CustomContentsController, type: :routing do
  let(:valid_user) {{ email: 'platform_user', password: 'rspec_test' }}
  let(:invalid_user) {{ email: 'bad_user', password: 'bad_pass' }}
  let(:host_servers) {{ join_server: "#{ENV['VCR_JOIN_SERVER']}", canvas_server: "#{ENV['VCR_CANVAS_SERVER']}" }}

  describe "Content Editor Smoke Tests" do
    describe "/custom_contents/new loads ckeditor", :js do
      let(:return_service) { '/custom_contents/new' }
      before(:each) do 
        visit "/cas/login?service=#{url_encode(return_service)}"
        VCR.configure do |c|
          c.ignore_localhost = true
        end
        VCR.use_cassette(join_cassette, :erb => host_servers) do
          fill_and_submit_login(username, password)
        end
      end

      context "when username and password are valid" do
        let(:join_cassette) { "join_auth_valid" }
        let(:username) { valid_user[:email] }
        let(:password) { valid_user[:password] }
        
        it "loads the editor view and renders react components" do
          expect(current_url).to include(return_service)
          expect(page).to have_title("Content Editor")
          expect(page).to have_selector("h1", text: "BRAVEN CONTENT EDITOR")
          expect(page).to have_content("Checklist Question")
        end

        it "loads the editor view and renders react components" do
          # Insert a question.
          find("li", text: "Section").click
          find("li", text: "Checklist Question").click

          # Make sure the question was inserted.
          expect(page).to have_selector("h5.ck-editor__editable.ck-editor__nested-editable")
          expect(page).to have_selector('input[type="checkbox"]')
        end
      end
    end
  end
end

def fill_and_submit_login(username, password)
  # Input login credentials
  fill_in "username", :with => username
  fill_in "password", :with => password
  
  # Make sure there is a login button that can be clicked
  # Capybara with Selenium can have problems with javascript
  find("#login-submit").click
end

end # if ENV['BZ_AUTH_SERVER']

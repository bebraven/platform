require "rails_helper"
require "capybara_helper"

include ERB::Util
include Rack::Utils

unless ENV['BZ_AUTH_SERVER'] # Only run these specs if on a server with local database authentication enabled

RSpec.describe CustomContentsController, type: :routing do
  let!(:valid_user) { create(:admin_user) }
  let(:valid_user_creds) {{ email: valid_user.email, password: valid_user.password }}

  describe "Content Editor Smoke Tests" do
    describe "/custom_contents/new loads ckeditor", :js do
      let(:return_service) { '/custom_contents/new' }
      before(:each) do 
        VCR.configure do |c|
          c.ignore_localhost = true
          # Must ignore the Capybara host IFF we are running tests that have browser AJAX requests to that host.
          c.ignore_hosts Capybara.server_host
        end
        #visit "/cas/login?service=#{url_encode(return_service)}"
        visit return_service
        fill_and_submit_login(username, password)
      end

      context "when username and password are valid" do
        let(:username) { valid_user_creds[:email] }
        let(:password) { valid_user_creds[:password] }
        
        it "loads the content editor and lists components" do
          expect(current_url).to include(return_service)
          expect(page).to have_title("Content Editor")
          expect(page).to have_selector("h1", text: "BRAVEN CONTENT EDITOR")
          expect(page).to have_content("Checklist Question")
        end

        it "inserts a checklist question" do
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

end # unless ENV['BZ_AUTH_SERVER']

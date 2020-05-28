require "rails_helper"
require "capybara_helper"

include ERB::Util
include Rack::Utils

unless ENV['BZ_AUTH_SERVER'] # Only run these specs if on a server with local database authentication enabled

RSpec.describe CourseContentsController, type: :routing do
  let!(:valid_user) { create(:admin_user) }
  let(:valid_user_creds) {{ email: valid_user.email, password: valid_user.password }}
  let(:invalid_user_creds) {{ email: 'bad_user', password: 'bad_pass' }}
  let(:host_servers) {{ canvas_server: "#{ENV['VCR_CANVAS_SERVER']}" }}

  describe "Content Editor Smoke Tests" do
    describe "/course_contents/new loads ckeditor", :js do
      let(:return_service) { '/course_contents/new' }
      before(:each) do 
        visit "/cas/login?service=#{url_encode(return_service)}"
        VCR.configure do |c|
          c.ignore_localhost = true
        end
        fill_and_submit_login(username, password)
      end

      context "when username and password are valid" do
        let(:username) { valid_user_creds[:email] }
        let(:password) { valid_user_creds[:password] }
        
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

end # unless ENV['BZ_AUTH_SERVER']

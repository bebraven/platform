require "rails_helper"
require "capybara_helper"
require "securerandom"

include ERB::Util
include Rack::Utils

unless ENV['BZ_AUTH_SERVER'] # Only run these specs if on a server with local database authentication enabled

RSpec.describe CourseContentsController, type: :feature do
  let!(:valid_user) { create(:admin_user) }
  let!(:assignment) { create(:course_content_assignment) }

  describe "xAPI assignment" do
    describe "/course_contents/:id loads show page", :js do
      let(:return_service) { "/course_contents/#{assignment.id}" }
      before(:each) do
        VCR.configure do |c|
          c.ignore_localhost = true
        end
        visit return_service
        fill_and_submit_login(valid_user.email, valid_user.password)
      end

      context "when username and password are valid" do
        it "shows the assignment" do
          # Do some basic tests first to give a little more granularity if this fails.
          expect(current_url).to include(return_service)
          expect(page).to have_title("Content Editor")
          expect(page).to have_content("Based on these responses,")
        end

        it "sends data to the LRS" do
          # Answer a question.
          unique_string = SecureRandom.uuid
          lrs_variables = {
            response: unique_string,
            lrs_url: Rails.application.secrets.lrs_url
          }

          VCR.use_cassette('lrs_xapi_proxy_send', :match_requests_on => [:path, :method], :erb => lrs_variables) do
            find("textarea").fill_in with: unique_string
            # The xAPI code runs on blur, so click off the textarea.
            find("p").click
            # Wait for the async JS to finish and update the DOM.
            expect(page).to have_selector("textarea[data-xapi-statement-id]")
          end

          # Check the LRS to make sure the answer actually got there.
          question_id = "h2c2-0600-next-steps"
          statement_id = find("textarea")['data-xapi-statement-id']

          lrs_variables['name'] = question_id
          lrs_variables['id'] = statement_id

          VCR.use_cassette('lrs_xapi_proxy_fetch', :match_requests_on => [:path, :method], :erb => lrs_variables) do
            lrs_query = "/statements?statementId=#{statement_id}&format=exact&attachments=false"
            visit "/data/xAPI/#{lrs_query}"
            xapi_response = JSON.parse page.text
            expect(xapi_response['id']).to eq statement_id
            expect(xapi_response['object']['definition']['name']['und']).to eq question_id
            expect(xapi_response['result']['response']).to eq unique_string
          end
        end
      end
    end
  end
end

end # unless ENV['BZ_AUTH_SERVER']

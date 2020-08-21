require "rails_helper"
require "capybara_helper"
require "securerandom"

include ERB::Util
include Rack::Utils

unless ENV['BZ_AUTH_SERVER'] # Only run these specs if on a server with local database authentication enabled

RSpec.describe CourseContentHistoriesController, type: :feature do
  let!(:project) { create(:course_content_assignment_with_versions) }
  let!(:lti_launch_assignment) { create(:lti_launch_assignment) }

  before(:each) do
    lti = Addressable::URI.parse(lti_launch_assignment.request_message.line_item_url)
    VCR.configure do |c|
      c.ignore_localhost = true
      # Must ignore the Capybara host IFF we are running tests that have browser AJAX requests to that host.
      c.ignore_hosts Capybara.server_host, lti.host,
      # Need this to pass :vcr option to describe blocks.
      c.configure_rspec_metadata!
    end

    allow_any_instance_of(LtiAdvantageAPI)
      .to receive(:get_access_token)
      .and_return('some access token')

    allow_any_instance_of(LtiAdvantageAPI)
      .to receive(:get_line_item_for_user)
      .and_return({})
  end

  after(:each) do
    # Print JS console errors, just in case we need them.
    # From https://stackoverflow.com/a/36774327/12432170.
    errors = page.driver.browser.manage.logs.get(:browser)
    if errors.present?
      message = errors.map(&:message).join("\n")
      puts message
    end
  end

  describe "xAPI project", :js do
    vcr_options = { :cassette_name => "lrs_xapi_proxy_load", :match_requests_on => [:path, :method] }
    describe "/course_contents/:id", :vcr => vcr_options do

      context "when valid LtiLaunch" do
        let!(:valid_user) { create(:fellow_user, admin: true) } # TODO: there is a bug where non-admin users redirect to Portal. Remove the admin: true when that's fixed.
        let!(:lti_launch) { create(:lti_launch_assignment, canvas_user_id: valid_user.canvas_id) }
        let(:return_service) {
          "/course_contents/#{project.id}"\
          "/versions/#{project.last_version.id}"\
          "?state=#{lti_launch.state}"
        }

        before(:each) do
          # Note that no login happens. The LtiAuthentication::WardenStrategy uses the lti_launch.state to authenticate.
          visit return_service
        end

        it "shows the project" do
          # Do some basic tests first to give a little more granularity if this fails.
          expect(current_url).to include(return_service)
          expect(page).to have_title("Content Editor")
          expect(page).to have_content("Based on these responses,")
        end

       # TODO: this test is broken on the final line.
       #it "fetches data from the lrs" do
       #  question_id = "h2c2-0600-next-steps"
       #  unique_string = SecureRandom.uuid
       #  lrs_variables = {
       #    response: unique_string,
       #    lrs_url: Rails.application.secrets.lrs_url,
       #    name: question_id,
       #    id: 'test',
       #  }

       #  VCR.use_cassette('lrs_xapi_proxy_load_previous', :match_requests_on => [:path, :method], :erb => lrs_variables) do
       #    visit return_service
       #    expect(page).to have_selector("[data-bz-retained=\"#{question_id}\"]")
       #    puts find_field('test-question-id').value
       #    expect(page).to have_field('test-question-id')
       #    expect(page).to have_field('test-question-id', with: unique_string)
       #  end
       #end

        it "sends data to the LRS" do
          # Answer a question.
          unique_string = SecureRandom.uuid
          lrs_variables = {
            response: unique_string,
            lrs_url: Rails.application.secrets.lrs_url
          }

          VCR.use_cassette('lrs_xapi_proxy_load_send', :match_requests_on => [:path, :method]) do
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

      # Note: these return a 500 error, but we can't check the response code with the Selenium driver
      # so we rely on the page title instead. 
      context "when LtiLaunch isn't found" do
        let(:return_service) {
          "/course_contents/#{project.id}"\
          "/versions/#{project.last_version.id}"\
          "?state=invalidltilaunchstate"
        }
        it "doesnt show the project" do
          page.config.raise_server_errors = false # Let the errors get converted into the actual server response so we can test that.
          visit return_service
          expect(page).not_to have_title("Content Editor")
        end
      end

      context "when user isn't found" do
        it "doesnt show the project" do
          page.config.raise_server_errors = false # Let the errors get converted into the actual server response so we can test that.
          lti_launch = create(
            :lti_launch_assignment,
            canvas_user_id: '987654321',
          )
          url = "/course_contents/#{project.id}"\
            "/versions/#{project.last_version.id}"\
            "?state=#{lti_launch.state}"
          visit url
          expect(page).not_to have_title("Content Editor")
        end
      end

    end
  end
end

end # unless ENV['BZ_AUTH_SERVER']

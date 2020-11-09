require "rails_helper"
require "capybara_helper"
require "securerandom"

include ERB::Util
include Rack::Utils

unless ENV['BZ_AUTH_SERVER'] # Only run these specs if on a server with local database authentication enabled

RSpec.describe ProjectSubmissionsController, type: :feature do
  let(:base_course_custom_content_version) { create :course_project_version }
  let(:section) { create :section, course: base_course_custom_content_version.base_course }
  let(:user) { create :fellow_user, section: section }
  let(:project_submission) { create(
    :project_submission,
    user: user,
    base_course_custom_content_version: base_course_custom_content_version,
  ) }
  let!(:lti_launch) {
    create(
      :lti_launch_assignment,
      canvas_user_id: project_submission.user.canvas_user_id,
    )
  }

  before(:each) do
    lti = Addressable::URI.parse(lti_launch.request_message.line_item_url)
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

  describe "GET #new", js: true, vcr: {
    :cassette_name => "lrs_xapi_proxy_load",
    :match_requests_on => [:path, :method],
  } do
    let(:url) {
      uri = Addressable::URI.parse(new_base_course_custom_content_version_project_submission_path(
        project_submission.base_course_custom_content_version,
      ))
      uri.query = { state: lti_launch.state }.to_query
      uri.to_s
    }

    before(:each) do
      # Note that no login happens. The LtiAuthentication::WardenStrategy uses the lti_launch.state to authenticate.
      visit url
    end

    # TODO: Figure out why this test is flaky.
    # It works when you only run this file and the test runs before
    # "sends data to the LRS". 
    # It might be that the shared LRS and reusing the question_id is causing 
    # the value to get overwritten?
    it "fetches the most recent data from the lrs - FLAKY", ci_exclude: true do
      question_id = "h2c2-0600-next-steps"
      unique_string = SecureRandom.uuid
      lrs_variables = {
        response: unique_string,
        lrs_url: Rails.application.secrets.lrs_url,
        name: question_id,
        id: 'test',
      }

      # Check that data is fetched
      VCR.use_cassette('lrs_xapi_proxy_load_previous', :match_requests_on => [:path, :method], :erb => lrs_variables) do
        visit url
        expect(page).to have_selector("[data-bz-retained=\"#{question_id}\"]")
        expect(page).to have_field('test-question-id')
        expect(page).to have_field('test-question-id', with: unique_string)
      end

      # Check that we called the endpoint in lrs_xapi_proxy_load_previous
      # without specifying the until query parameter
      expect(WebMock)
        .to have_requested(:get, 'https://lrs.braven.org/data/xAPI/statements')
        .with(query: hash_excluding({until: nil}))
        .at_least_once
    end

    [
      { element: 'textarea', value: '' },
      { element: 'textarea', value: SecureRandom.uuid},
      { element: 'select', value: 'A' },
    ].each do |input|
      it 'sends the input value to the LRS' do
        VCR.use_cassette(
          'lrs_xapi_proxy_load_send',
          :match_requests_on => [:path, :method],
        ) do
          find(input[:element]).set input[:value]
          # The xAPI code runs on blur, so click off the element.
          find("p").click
          # Wait for the async JS to finish and update the DOM.
          expect(page).to have_selector("#{input[:element]}[data-xapi-statement-id]")
        end

        # Check the LRS to make sure the answer actually got there.
        question_id = "h2c2-0600-next-steps"
        statement_id = find("#{input[:element]}")['data-xapi-statement-id']

        lrs_variables = {
          response: input[:value],
          lrs_url: Rails.application.secrets.lrs_url,
          id: statement_id,
        }

        VCR.use_cassette('lrs_xapi_proxy_fetch', :match_requests_on => [:path, :method], :erb => lrs_variables) do
          lrs_query = "/statements?statementId=#{statement_id}&format=exact&attachments=false"
          visit "/data/xAPI/#{lrs_query}"
          xapi_response = JSON.parse page.text
          expect(xapi_response['id']).to eq statement_id
          expect(xapi_response['object']['definition']['name']['und']).to eq question_id
          expect(xapi_response['result']['response']).to eq input[:value]
        end
      end
    end
  end

  describe "GET #show", js: true, vcr: {
    :cassette_name => "lrs_xapi_proxy_load",
    :match_requests_on => [:path, :method],
  } do
    before(:each) do
      # Note that no login happens. The LtiAuthentication::WardenStrategy uses the lti_launch.state to authenticate.
      visit url
    end

    context "when valid LtiLaunch" do
      let(:url) {
        uri = Addressable::URI.parse(project_submission_path(
          project_submission,
        ))
        uri.query = { state: lti_launch.state }.to_query
        uri.to_s
      }

      it "fetches only the data for the submission - FLAKY", ci_exclude: true do
        question_id = "h2c2-0600-next-steps"
        unique_string = SecureRandom.uuid
        lrs_variables = {
          response: unique_string,
          lrs_url: Rails.application.secrets.lrs_url,
          name: question_id,
          id: 'test',
        }

        # Add in created_at time
        project_submission.created_at = Time.now
        project_submission.save!

        # Check that data is fetched
        VCR.use_cassette('lrs_xapi_proxy_load_previous', :match_requests_on => [:path, :method], :erb => lrs_variables) do
          visit url
          expect(page).to have_selector("[data-bz-retained=\"#{question_id}\"]")
          expect(page).to have_field('test-question-id', disabled: true)
          # We can't test this because the field is disabled and we're not
          # able to actually fill it in with the recording
          #expect(page).to have_field('test-question-id', disabled: true, with: unique_string)
        end

        # Check that we called the endpoint in lrs_xapi_proxy_load_previous
        # with the "until" parameter
        expect(WebMock)
          .to have_requested(:get, 'https://lrs.braven.org/data/xAPI/statements')
          .with(query: hash_including({until: project_submission.created_at.iso8601}))
          .at_least_once
      end

      it "shows the submission" do
        # Do some basic tests first to give a little more granularity if this fails.
        expect(current_url).to include(url)
        expect(page).to have_title("Project")
        expect(page).to have_content("Based on these responses,")
      end

      it "cannot be edited" do
        save_and_open_page
        # Disabled
        expect(page).to have_field(
          'test-question-id',
          type: 'textarea',
          disabled: true,
        )
        # Highlighted
        expect(page).to have_css('textarea.highlighted-user-input')
      end
    end

    # Note: these return a 500 error, but we can't check the response code with the Selenium driver
    # so we rely on the page title instead. 
    context "when LtiLaunch isn't found" do
      let(:url) {
        uri = Addressable::URI.parse(project_submission_path(
          project_submission,
        ))
        uri.query = { state: "invalidltilaunchstate" }.to_query
        uri.to_s
      }

      it "doesn't show the submission" do
        page.config.raise_server_errors = false # Let the errors get converted into the actual server response so we can test that.
        expect(page).not_to have_title("Content Editor")
      end
    end

    context "when user isn't found" do
      let(:lti_launch_with_invalid_user) {
        lti_launch = create(
          :lti_launch_assignment,
          canvas_user_id: '987654321',
        )
      }
      let(:url) {
        uri = Addressable::URI.parse(project_submission_path(
          project_submission,
        ))
        uri.query = { state: lti_launch_with_invalid_user.state }.to_query
        uri.to_s
      }

      it "doesnt show the submission" do
        page.config.raise_server_errors = false # Let the errors get converted into the actual server response so we can test that.
        expect(page).not_to have_title("Content Editor")
      end
    end
  end
end
end # unless ENV['BZ_AUTH_SERVER']

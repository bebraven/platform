require 'rails_helper'
require 'capybara_helper'

require 'lti_advantage_api'
require 'lti_score'

RSpec.feature 'Submit a project', :type => :feature do
  let!(:valid_user) { create(:fellow_user) }
  let!(:project) { create(:custom_content_assignment_with_version) }

  let!(:lti_launch) { 
    create(
      :lti_launch_assignment, 
      canvas_user_id: valid_user.canvas_id,
      course_id: project.id,
    )
  }
  let(:lti_advantage_access_token) { 
    FactoryBot.json(:lti_advantage_access_token)
  }

  let(:uri) {
    path = Addressable::URI.parse(custom_content_custom_content_version_path(
      project.id,
      project.last_version.id,
    ))
    # To let us bypass login using the state query parameter
    path.query = { state: lti_launch.state }.to_query
    path.to_s
  }

  before(:each) do
    # We need to ignore these hosts because VCR can't record AJAX requests
    lrs = Addressable::URI.parse(Rails.application.secrets.lrs_url)
    lti = Addressable::URI.parse(lti_launch.request_message.line_item_url)

    VCR.configure do |c|
      c.ignore_localhost = true
      # Ignore AJAX requests to platformweb, xapi_assignment, Canvas LTI
      c.ignore_hosts Capybara.server_host, lrs.host, lti.host
    end

    # Stubs for interacting with Canvas for submissions
    allow_any_instance_of(LtiAdvantageAPI)
      .to receive(:get_access_token)
      .and_return(lti_advantage_access_token)
    allow_any_instance_of(LtiAdvantageAPI)
      .to receive(:get_line_item_for_user)
      .and_return({})
    allow_any_instance_of(LtiAdvantageAPI)
      .to receive(:create_score)
      .and_return({body: '{}'})
  end

  describe "valid project submission" do
    context "viewed as TA" do
      it "does not show a submit button", js: true do
        uri_with_user_override = Addressable::URI.parse(
          custom_content_custom_content_version_path(
            project.id,
            project.last_version.id,
          ),
        )
        uri_with_user_override.query = {
          state: lti_launch.state,
          user_override_id: valid_user.id, # Student's submission to view
        }.to_query

        visit uri_with_user_override.to_s

        expect(page).to_not have_button('project-submit-button')
      end
    end

    context "viewed as student" do
      it "shows a submit button", js: true do
        visit uri
        expect(page).to have_button('project-submit-button')
        expect(page).to have_button('Submit')
      end

      it "shows a re-submit button", js: true do
        allow_any_instance_of(LtiAdvantageAPI)
          .to receive(:get_line_item_for_user)
          .and_return({key: 'val'})

        visit uri
        expect(page).to have_button('project-submit-button')
        expect(page).to have_button('Re-Submit')
      end

      it "creates a new submission", js: true do
        visit uri
        click_button 'project-submit-button'

        expect(page).to have_selector('.alert')
        expect(page).to have_selector('.alert-success')
      end

      it "updates button text after submission", js: true do
        allow_any_instance_of(LtiAdvantageAPI)
          .to receive(:get_line_item_for_user)
          .and_return({key: 'val'})

        visit uri
        click_button 'project-submit-button'

        # Wait for and close the alert
        expect(page).to have_selector('.alert')
        expect(page).to have_selector('.alert-success')
        find('button.close').click

        expect(page).to have_button('project-submit-button')
        expect(page).to have_button('Re-Submit')
      end
    end
  end

  describe "invalid assignment submission" do
    context "with previous submission" do
      it "still shows re-submit button text", js: true do
        allow_any_instance_of(LtiAdvantageAPI)
          .to receive(:get_line_item_for_user)
          .and_return({key: 'val'})

        # Generate an error when we're trying to create the submission
        allow_any_instance_of(LtiAdvantageAPI)
          .to receive(:create_score)
          .and_raise('failed to create another submission')

        # Suppress these so we can verify that the UI handles errors
        page.config.raise_server_errors = false

        visit uri

        expect(page).to have_button('Re-Submit')
        click_button 'project-submit-button'

        expect(page).to have_selector('.alert-warning')
        find('button.close').click

        expect(page).to have_button('project-submit-button')
        expect(page).to have_button('Re-Submit')
      end
    end

    context "no LTI state" do
      it "shows an error", js: true do
        # Suppress these so we can verify that the UI handles errors
        page.config.raise_server_errors = false

        visit uri

        # Make the LTI state ID invalid
        # Capybara's fill_in doesn't work because the input is hidden
        page.execute_script(
          "document.querySelector('input[type=\"hidden\"][name=\"state\"]').value = 'invalidstate'"
        )
        click_button 'project-submit-button'

        expect(page).to have_selector('.alert-warning')

      end
    end
  end
end

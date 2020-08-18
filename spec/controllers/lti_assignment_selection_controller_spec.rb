require 'rails_helper'

RSpec.describe LtiAssignmentSelectionController, type: :controller do

  # TODO: once we fix this up to not require a logged in platform user, remove this.
  # Assignment Selection should be allowed just by logging into Canvas.
  render_views
  let(:user) { create :admin_user }

  before(:each) do
    sign_in user
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # LtiAssignmentSelectionController. Be sure to keep this updated too.
  let(:valid_session) { {} } # TODO: remove this once we don't require a valid session for the logged in user.

  let(:state) { LtiLaunchController.generate_state }
  let(:target_link_uri) { 'https://target/link' }
  let(:lti_launch) { create(:lti_launch_assignment_selection, target_link_uri: target_link_uri, state: state) }
  let!(:assignment) { create(:course_content_assignment) }

  describe "GET #new" do
    it "returns a success response" do
      get :new, params: {state: state}, session: valid_session
      expect(response).to be_successful
    end

    it "includes the existing assignment as an option" do
      get :new, params: {state: state}, session: valid_session
      expect(response.body).to match /<option value="#{assignment.id}"/
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "shows the confirmation form and preview iframe" do
        expected_url = LtiDeepLinkingRequestMessage.new(lti_launch.id_token_payload).deep_link_return_url

        post :create, params: {state: lti_launch.state, assignment_id: assignment.id}, session: valid_session
        expect(response.body).to match /<form action="#{Regexp.escape(expected_url)}"/
        expect(response.body).to match /<iframe src=".*\/#{assignment.id}"/
      end

      it 'saves a new version of the project' do
        expect { post :create, params: {state: lti_launch.state, assignment_id: assignment.id}, session: valid_session }.to change {CourseContentHistory.count}.by(1)
        expect(assignment.body).to eq(CourseContentHistory.last.body)
      end

    end

    context "with invalid params" do
      it "raises an error when state param is missing" do
        expect {
          post :create, params: {assignment_id: assignment.id}, session: valid_session
        }.to raise_error ActionController::ParameterMissing
      end

      it "raises an error when assignment_id param is missing" do
        expect {
          post :create, params: {state: state}, session: valid_session
        }.to raise_error ActionController::ParameterMissing
      end
    end
  end

end

require 'rails_helper'

RSpec.describe LtiAssignmentSelectionController, type: :controller do
  render_views

  let(:state) { LtiLaunchController.generate_state }
  let(:target_link_uri) { 'https://target/link' }
  let!(:lti_launch) { create(:lti_launch_assignment_selection, target_link_uri: target_link_uri, state: state) }
  let!(:assignment) { create(:course_content_assignment) }
  let!(:user) { create :registered_user, admin: true, canvas_id: lti_launch.request_message.canvas_user_id} # TODO: bug where you have to be an admin. Remove admin once that's fixed.

  describe "GET #new" do
    it "returns a success response" do
      get :new, params: {state: state}
      expect(response).to be_successful
    end

    it "includes the existing assignment as an option" do
      get :new, params: {state: state}
      expect(response.body).to match /<option value="#{assignment.id}"/
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "shows the confirmation form and preview iframe" do
        expected_url = LtiDeepLinkingRequestMessage.new(lti_launch.id_token_payload).deep_link_return_url

        post :create, params: {state: lti_launch.state, assignment_id: assignment.id}
        expect(response.body).to match /<form action="#{Regexp.escape(expected_url)}"/
        preview_url = "/course_contents/#{assignment.id}?state=#{state}" # We preview without the specific version b/c we don't want it talking to the LRS
        expect(response.body).to match /<iframe src="#{Regexp.escape(preview_url)}"/
      end

      it 'saves a new version of the project' do
        expect { post :create, params: {state: lti_launch.state, assignment_id: assignment.id} }.to change {CourseContentHistory.count}.by(1)
        expect(assignment.body).to eq(CourseContentHistory.last.body)
      end

    end

    context "with invalid params" do
      it "redirects to login when state param is missing" do
        post :create, params: {assignment_id: assignment.id}
        expect(response).to redirect_to(new_user_session_path)
      end

      it "raises an error when assignment_id param is missing" do
        expect {
          post :create, params: {state: state}
        }.to raise_error ActionController::ParameterMissing
      end
    end
  end

end

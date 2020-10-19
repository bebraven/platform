require 'rails_helper'

RSpec.describe LtiAssignmentSelectionController, type: :controller do
  render_views

  let(:state) { LtiLaunchController.generate_state }
  let(:target_link_uri) { 'https://target/link' }
  let!(:lti_launch) { create(:lti_launch_assignment_selection, target_link_uri: target_link_uri, state: state) }
  let!(:assignment) { create(:custom_content_assignment) }
  let!(:user) { create :admin_user, canvas_user_id: lti_launch.request_message.canvas_user_id}

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

end

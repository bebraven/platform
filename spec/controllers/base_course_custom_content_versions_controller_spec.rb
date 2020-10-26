require 'rails_helper'

RSpec.describe BaseCourseCustomContentVersionsController, type: :controller do
  render_views

  let(:base_course_custom_content_version) { create :course_project_version }
  let(:state) { LtiLaunchController.generate_state }
  let(:target_link_uri) { 'https://target/link' }
  let(:course) { create :course_with_canvas_id }
  let!(:lti_launch) {
    create(
      :lti_launch_assignment_selection,
      target_link_uri: target_link_uri,
      state: state,
      course_id: course.canvas_course_id,
    )
  }
  let!(:user) { create :admin_user, canvas_user_id: lti_launch.request_message.canvas_user_id}

  describe "POST #create" do
    context "with valid params" do
      let(:custom_content) { create :project }

      it "shows the confirmation form and preview iframe" do
        expected_url = LtiDeepLinkingRequestMessage.new(lti_launch.id_token_payload).deep_link_return_url

        post :create, params: {state: lti_launch.state, custom_content_id: custom_content.id}
        expect(response.body).to match /<form action="#{Regexp.escape(expected_url)}"/
        preview_url = "/custom_contents/#{custom_content.id}?state=#{state}" # We preview without the specific version b/c we don't want it talking to the LRS
        expect(response.body).to match /<iframe src="#{Regexp.escape(preview_url)}"/
      end

      it 'saves a new version of the project' do
        expect {
          post :create, params: {
            state: lti_launch.state,
            custom_content_id: custom_content.id,
          }
        }.to change {CustomContentVersion.count}.by(1)
        expect(custom_content.body).to eq(CustomContentVersion.last.body)
      end
    end

    context "with invalid params" do
      let(:custom_content) { create :project }

      it "redirects to login when state param is missing" do
        post :create, params: {custom_content_id: custom_content.id}
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

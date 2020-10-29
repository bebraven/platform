require 'rails_helper'

RSpec.describe BaseCourseCustomContentVersionsController, type: :controller do
  render_views

##########
# TODO: refactor the below "POST #create" tests to work with the new
# Course Management approach for publishing a Project/Survey
#######

context "TODO refactor old specs" do

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
end # "TODO refactor old specs"
################
#### END TODO
################

  let!(:admin_user) { create :admin_user }
  let(:course) { create :course_with_canvas_id }
  let(:course_project_version) { create :course_project_version, base_course: course }
  let(:invalid_edit_project_params) { {base_course_id: course_project_version.base_course_id, id: course_project_version} }
  let(:course_template) { create :course_template_with_canvas_id }
  let(:course_template_project_version) { create :course_template_project_version, base_course: course_template }
  let(:valid_edit_project_params) { {base_course_id: course_template_project_version.base_course_id, id: course_template_project_version} }
  let(:canvas_client) { double(CanvasAPI) }


  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # BaseCourseCustomContentVersionsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  before(:each) do
    allow(CanvasAPI).to receive(:client).and_return(canvas_client)
  end

  context 'when logged in as admin user' do
    before do
      sign_in admin_user
    end  

    describe 'POST #update' do
     context 'with invalid params' do
        it 'throws when not a CourseTemplate' do
          expect { post :update, params: invalid_edit_project_params, session: valid_session }.to raise_error(BaseCourse::BaseCourseEditError)
        end
      end
    end # 'POST #update'

    describe 'POST #delete' do
      context 'with invalid params' do
        it 'throws when not a CourseTemplate' do
          expect { post :destroy, params: invalid_edit_project_params, session: valid_session }.to raise_error(BaseCourse::BaseCourseEditError)
        end
      end
    end # 'POST #delete

  end # logged in as admin user
end

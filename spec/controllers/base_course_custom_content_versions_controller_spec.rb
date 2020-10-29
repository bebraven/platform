require 'rails_helper'

RSpec.describe BaseCourseCustomContentVersionsController, type: :controller do
  render_views

  let(:target_link_uri) { 'https://target/link' }
  let(:course) { create :course_with_canvas_id }
  let!(:admin_user) { create :admin_user }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # BaseCourseCustomContentVersionsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  context 'when logged in as admin user' do
    before do
      sign_in admin_user
    end

    # TODO: cut this over to the new create logic
    describe 'POST #create' do
      context 'with valid params' do
        let(:custom_content) { create :project }
  
        xit 'shows the confirmation form and preview iframe' do
          expected_url = LtiDeepLinkingRequestMessage.new(lti_launch.id_token_payload).deep_link_return_url
  
          post :create, params: {state: lti_launch.state, custom_content_id: custom_content.id}
          expect(response.body).to match /<form action="#{Regexp.escape(expected_url)}"/
          preview_url = "/custom_contents/#{custom_content.id}?state=#{state}" # We preview without the specific version b/c we don't want it talking to the LRS
          expect(response.body).to match /<iframe src="#{Regexp.escape(preview_url)}"/
        end
  
        xit 'saves a new version of the project' do
          expect {
            post :create, params: {
              state: lti_launch.state,
              custom_content_id: custom_content.id,
            }
          }.to change {CustomContentVersion.count}.by(1)
          expect(custom_content.body).to eq(CustomContentVersion.last.body)
        end
      end
  
      context 'with invalid params' do
        let(:custom_content) { create :project }
  
        xit 'redirects to login when state param is missing' do
          post :create, params: {custom_content_id: custom_content.id}
          expect(response).to redirect_to(new_user_session_path)
        end
  
        xit 'raises an error when assignment_id param is missing' do
          expect {
            post :create, params: {state: state}
          }.to raise_error ActionController::ParameterMissing
        end
      end
    end # 'POST #create'
  
    describe 'POST #update' do
      context 'with valid params' do

        context 'for project' do
          let!(:course_template_project_version) { create :course_template_project_version }
          let(:valid_project_params) { {base_course_id: course_template_project_version.base_course_id, id: course_template_project_version} }
          let(:new_body) { 'updated project body' }

          before(:each) do
            project = course_template_project_version.custom_content_version.parent
            project.body = new_body
            project.save!
          end
  
          it 'saves a new version of the project' do
            expect { post :update, params: valid_project_params, session: valid_session }.to change {ProjectVersion.count}.by(1)
          end

          it 'associates the exsiting BaseCourseCustomContentVersion to the new content version' do
            expect(course_template_project_version.custom_content_version.body).not_to eq(new_body)
            expect { post :update, params: valid_project_params, session: valid_session }.not_to change {BaseCourseCustomContentVersion.count}
            expect(BaseCourseCustomContentVersion.find(course_template_project_version.id).custom_content_version).to eq(ProjectVersion.last)
          end

          it 'redirects back to edit page and flashes message' do
            response = post :update, params: valid_project_params, session: valid_session
            expect(response).to redirect_to(edit_course_template_path)
            expect(flash[:notice]).to match /successfully published/
          end
        end
      end

      context 'with invalid params' do

        let(:course_project_version) { create :course_project_version }
        let(:invalid_project_params) { {base_course_id: course_project_version.base_course_id, id: course_project_version} }
  
        it 'throws when not a CourseTemplate' do
          expect { post :update, params: invalid_project_params, session: valid_session }.to raise_error(BaseCourse::BaseCourseEditError)
        end

      end
    end # 'POST #update'
  end # logged in as admin user
end

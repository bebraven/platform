require 'rails_helper'
require 'rise360_util'

RSpec.describe CourseResourcesController, type: :controller do
  render_views

  context "with normal signin" do
    let(:user) { create :admin_user }

    before do
      sign_in user
    end

    describe "GET #new" do
      it "returns a success response" do
        get :new
        expect(response).to be_successful
      end

      it "includes a file input" do
        get :new
        expect(response.body).to match /<input type="file" name="course_resource_zipfile" id="course_resource_zipfile"/
      end
    end

    describe "POST #create" do
      let(:file_upload) { fixture_file_upload(Rails.root.join('spec/fixtures', 'example_rise360_package.zip'), 'application/zip') }

      context "with invalid params" do
        it "raises an error when required param is missing" do
          expect {
            post :create
          }.to raise_error ActionController::ParameterMissing
        end
      end

      context "with valid params" do
        let(:create_course_resource) { post :create, params: {name: 'test', course_resource_zipfile: file_upload} }

        it "redirects to base_courses_path" do
          launch_path = '/lessons/somekey/index.html'
          allow(Rise360Util).to receive(:launch_path).and_return(launch_path)
          allow(Rise360Util).to receive(:publish).and_return(launch_path)

          expect(create_course_resource).to redirect_to base_courses_path
        end

        it 'attaches uploaded zipfile' do
          launch_path = '/lessons/somekey/index.html'
          allow(Rise360Util).to receive(:launch_path).and_return(launch_path)
          allow(Rise360Util).to receive(:publish).and_return(launch_path)

          expect {
            post :create, params: {name: 'test', course_resource_zipfile: file_upload}
          }.to change(ActiveStorage::Attachment, :count).by(1)
          expect(CourseResource.last.course_resource_zipfile).to be_attached
        end
      end
    end
  end

  context "with LTI launch" do
    let(:state) { LtiLaunchController.generate_state }
    let(:canvas_course_id) { '54321' }
    let(:launch_path) { '/lessons/somekey/index.html' }
    let(:lti_launch) { create(:lti_launch_resource_link_request, target_link_uri: 'https://target/link', course_id: canvas_course_id, state: state) }
    let!(:user) { create :registered_user, canvas_id: lti_launch.request_message.canvas_user_id }

    describe "GET #lti_show" do

      before(:each) do
        allow(Rise360Util).to receive(:launch_path).and_return(launch_path)
        allow(Rise360Util).to receive(:publish).and_return(launch_path)
      end

      context 'existing course resource' do

        context 'for course' do
          it 'redirects to public url' do
            course = create(:course_with_resource, canvas_course_id: canvas_course_id)
  
            get :lti_show, params: {:id => course.course_resource.id, :state => state}
  
            redirect_url = Addressable::URI.parse(response.location)
            expected_url =  Addressable::URI.parse(course.course_resource.launch_url)
            expect(redirect_url.path).to eq(expected_url.path)
          end
        end

        context 'for course resource' do
          it 'redirects to public url' do
            course_template = create(:course_template_with_resource, canvas_course_id: canvas_course_id)
  
            get :lti_show, params: {:id => course_template.course_resource.id, :state => state}
  
            redirect_url = Addressable::URI.parse(response.location)
            expected_url =  Addressable::URI.parse(course_template.course_resource.launch_url)
            expect(redirect_url.path).to eq(expected_url.path)
          end
        end 

      end
    end
  end
end

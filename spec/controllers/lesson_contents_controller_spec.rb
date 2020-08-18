require 'rails_helper'
require 'lesson_content_publisher'

RSpec.describe LessonContentsController, type: :controller do
  # TODO: https://app.asana.com/0/1174274412967132/1184057808812010
  render_views

  let(:user) { create :admin_user }

  before(:each) do
    sign_in user
  end

  # TODO: https://app.asana.com/0/1174274412967132/1184057808812010
  let(:valid_session) { {} } 
  let(:state) { LtiLaunchController.generate_state }

  describe "GET #new" do
    it "returns a success response" do
      get :new, params: {state: state}, session: valid_session
      expect(response).to be_successful
    end

    it "includes a file input" do
      get :new, params: {state: state}, session: valid_session
      expect(response.body).to match /<input type="file" name="lesson_content_zipfile" id="lesson_content_zipfile"/
    end
  end

  describe "GET #show" do
    let(:lesson_content_with_zipfile) { create(:lesson_content_with_zipfile) }
    context 'existing lesson content' do
      it 'redirects to public url with LRS query parameters' do
        launch_path = '/lessons/somekey/index.html'
        allow(LessonContentPublisher).to receive(:launch_path).and_return(launch_path)
        allow(LessonContentPublisher).to receive(:publish).and_return(launch_path)

        get :show, params: {:id => lesson_content_with_zipfile.id}, session: valid_session

        redirect_url = Addressable::URI.parse(response.location)
        expected_url =  Addressable::URI.parse(lesson_content_with_zipfile.launch_url)
        expect(redirect_url.path).to eq(expected_url.path)

        # Specific LRS query parameters are tested in LessonContentsHelper
        expect(redirect_url.query_values).not_to be_empty
      end
    end
  end

  describe "POST #create" do
    let(:file_upload) { fixture_file_upload(Rails.root.join('spec/fixtures', 'example_rise360_package.zip'), 'application/zip') }
    let!(:lti_launch) { create(:lti_launch_assignment_selection, target_link_uri: 'https://target/link', state: state) }

    context "with invalid params" do
      it "raises an error when state param is missing" do
        expect {
          post :create, params: {lesson_content_zipfile: file_upload}, session: valid_session
        }.to raise_error ActionController::ParameterMissing
      end

      it "raises an error when zipfile param is missing" do
        expect {
          post :create, params: {state: state}, session: valid_session
        }.to raise_error ActionController::ParameterMissing
      end
    end

    context "with valid params" do
      it "shows the confirmation form and preview iframe" do
        launch_path = '/lessons/somekey/index.html'
        allow(LessonContentPublisher).to receive(:launch_path).and_return(launch_path)
        allow(LessonContentPublisher).to receive(:publish).and_return(launch_path)

        post :create, params: {state: state, lesson_content_zipfile: file_upload}, session: valid_session

        expected_url = LtiDeepLinkingRequestMessage.new(lti_launch.id_token_payload).deep_link_return_url
        expect(response.body).to match /<form action="#{Regexp.escape(expected_url)}"/

        lesson_content_url = lesson_content_url(LessonContent.last)
        expect(response.body).to match /<iframe id="lesson-content-preview" src="#{lesson_content_url}"/
      end

      it 'attaches uploaded zipfile' do
        launch_path = '/lessons/somekey/index.html'
        allow(LessonContentPublisher).to receive(:launch_path).and_return(launch_path)
        allow(LessonContentPublisher).to receive(:publish).and_return(launch_path)

        expect {
          post :create, params: {state: state, lesson_content_zipfile: file_upload} , session: valid_session
        }.to change(ActiveStorage::Attachment, :count).by(1)
        expect(LessonContent.last.lesson_content_zipfile).to be_attached
      end
    end
  end
end

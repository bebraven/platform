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

  let(:state) { SecureRandom.uuid }
  let(:target_link_uri) { 'https://target/link' }
  let!(:lti_launch) { create(:lti_launch_deep_link, target_link_uri: target_link_uri, state: state) }
  let(:lesson_content) { create(:lesson_content) }
  let(:lesson_content_with_zipfile) { create(:lesson_content_with_zipfile) }
  let(:lesson_content_zipfile) { fixture_file_upload(Rails.root.join('spec/fixtures', 'example_rise360_package.zip'), 'application/zip') }

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
    context 'existing lesson content' do
      it 'redirects to public url' do
        launch_url = 'https://S3-bucket-path/lessons/somekey/index.html'
        allow(LessonContentPublisher).to receive(:launch_url).and_return(launch_url)
        allow(LessonContentPublisher).to receive(:publish).and_return(launch_url)
        get :show, params: {:id => lesson_content_with_zipfile.id}, session: valid_session
        expect(response).to redirect_to(launch_url)
      end
    end
  end

  describe "POST #create" do
    context "with invalid params" do
      it "raises an error when state param is missing" do
        expect {
          post :create, params: {lesson_content_zipfile: lesson_content_zipfile}, session: valid_session
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
        expected_url = LtiDeepLinkingRequestMessage.new(lti_launch.id_token_payload).deep_link_return_url
        post :create, params: {state: state, lesson_content_zipfile: lesson_content_zipfile}, session: valid_session
        expect(response.body).to match /<form action="#{expected_url}"/

        lesson_content_url = lesson_content_url(LessonContent.last)
        expect(response.body).to match /<iframe id="lesson-content-preview" src="#{lesson_content_url}"/
      end

      # From: https://www.dwightwatson.com/posts/testing-activestorage-uploads-in-rails-52
      it 'attaches uploaded zipfile' do
        expect {
          post :create, params: {state: state, lesson_content_zipfile: lesson_content_zipfile} , session: valid_session
        }.to change(ActiveStorage::Attachment, :count).by(1)
        expect(LessonContent.last.lesson_content_zipfile).to be_attached
      end
    end
  end

end

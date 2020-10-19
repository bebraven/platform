require 'rails_helper'
require 'lti_score'

RSpec.describe ProjectSubmissionsController, type: :controller do
  render_views

  describe 'GET #show' do
    let(:project) { create :project }
    let(:user) { create :fellow_user, section: section }
    let(:project_submission) { create :project_submission, project_id: project.id, user: user }
    let(:course_project) { create :course_project, project_id: project.id }
    let(:section) { create :section, base_course_id: course_project.base_course_id }

    context "as a Fellow" do
      let(:lti_launch) {
        create(
          :lti_launch_assignment,
          canvas_user_id: project_submission.user.canvas_user_id,
        )
      }

      it 'returns a success response' do
        allow(LtiLaunch).to receive(:current).and_return(lti_launch)
        allow(lti_launch).to receive(:activity_id).and_return('some_activity_id')
        get(
          :show,
          params: {
            project_id: project_submission.project.id,
            id: project_submission.id,
            state: lti_launch.state,
          },
        )
        expect(response).to be_successful
      end

      it 'checks submission time to fetch answers' do
        # We can't just stub/expect on the project_submission object we created
        # because the controller action loads a different object
        allow_any_instance_of(ProjectSubmission)
          .to receive(:created_at)
          .and_return(Time.now)

        expect_any_instance_of(ProjectSubmission)
          .to receive(:created_at)
          .once

        get(
          :show,
          params: {
            project_id: project_submission.project.id,
            id: project_submission.id,
            state: lti_launch.state,
          },
        )
      end
    end

    context "as a TA" do
      let(:user) { create :ta_user, section: section }
      let(:lti_launch) {
        create :lti_launch_assignment, canvas_user_id: user.canvas_user_id
      }

      it 'returns a success response' do
        allow(LtiLaunch).to receive(:current).and_return(lti_launch)
        allow(lti_launch).to receive(:activity_id).and_return('some_activity_id')
        get(
          :show,
          params: {
            project_id: project_submission.project.id,
            id: project_submission.id,
            state: lti_launch.state,
          },
        )
        expect(response).to be_successful
      end
    end

    context "as not logged in" do
      let(:lti_launch) { create :lti_launch_assignment }

      it 'redirects to login' do
        allow(LtiLaunch).to receive(:current).and_return(lti_launch)
        allow(lti_launch).to receive(:activity_id).and_return('some_activity_id')
        get(
          :show,
          params: {
            project_id: project_submission.project_id,
            id: project_submission.id,
            # state: not passed in, will redirect to login
          },
        )
        expect(response).to redirect_to('/users/sign_in')
      end
    end
  end

  describe 'GET #new' do
    let(:project) { create :project }
    let(:lti_launch) { create :lti_launch_assignment }

    it 'returns a success response' do
      allow(LtiLaunch).to receive(:current).and_return(lti_launch)
      allow(lti_launch).to receive(:activity_id).and_return('some_activity_id')
      get(
        :new,
        params: {
          project_id: project.id,
          state: lti_launch.state,
        },
      )
      expect(response).to be_successful
    end

    it 'redirects to login' do
      allow(LtiLaunch).to receive(:current).and_return(lti_launch)
      allow(lti_launch).to receive(:activity_id).and_return('some_activity_id')
      get(
        :new,
        params: {
          project_id: project.id,
          # state: not passed in, will redirect to login
        },
      )
      expect(response).to redirect_to('/users/sign_in')
    end
  end

  describe 'POST #create' do
    let(:project) { create(:project) }
    let(:course_project) { create :course_project, project_id: project.id }
    let(:section) { create :section, base_course_id: course_project.base_course_id }
    let(:user) { create :fellow_user, section: section }

    let(:lti_launch) {
      create(:lti_launch_assignment, canvas_user_id: user.canvas_user_id)
    }

    it 'creates a submission' do
      allow_any_instance_of(LtiAdvantageAPI)
        .to receive(:get_access_token)
        .and_return('oasjfoasjofdj')

      stub_request(:post, "#{lti_launch.request_message.line_item_url}/scores").to_return(body: '{"fake" : "response"}')

      expect {
        post(
          :create,
          params: {
            project_id: project.id,
            state: lti_launch.state,
          },
        )
      }.to change {ProjectSubmission.count}.by(1)
      ps = ProjectSubmission.last
      submission_url = project_project_submission_url(ps.project, ps)

      expect(WebMock)
        .to have_requested(
          :post,
          "#{lti_launch.request_message.line_item_url}/scores",
        )
        .with { |req|
          body = JSON.parse(req.body)
          body['userId'].to_i == user.canvas_user_id.to_i \
          && body[LtiScore::LTI_SCORE_SUBMISSION_URL_KEY]['submission_data'] == submission_url
        }
        .once
    end

    it 'redirects to login' do
      allow(LtiLaunch).to receive(:current).and_return(lti_launch)
      allow(lti_launch).to receive(:activity_id).and_return('some_activity_id')
      post(
        :new,
        params: {
          project_id: project.id,
          # state: not passed in, will redirect to login
        },
      )
      expect(response).to redirect_to('/users/sign_in')
    end
  end
end

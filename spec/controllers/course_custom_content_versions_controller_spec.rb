require 'rails_helper'

RSpec.describe CourseCustomContentVersionsController, type: :controller do
  render_views

  let!(:admin_user) { create :admin_user }
  let(:course) { create :course }
  let(:project) { create :project }
  let(:project_version) { create :project_version, project: project }
  let(:course_project_version) { create :course_project_version, course: course, project_version: project_version }
  let(:valid_project_params) { {course_id: course_project_version.course_id, id: course_project_version, type: 'CourseProjectVersion' } }
  let(:canvas_new_rubric) { create :canvas_rubric, course_id: course.id }
  let(:survey) { create :survey }
  let(:survey_version) { create :survey_version, survey: survey }
  let(:course_survey_version) { create :course_survey_version, course: course, survey_version: survey_version }
  let(:valid_survey_params) { {course_id: course_survey_version.course_id, id: course_survey_version, type: 'CourseSurveyVersion' } }
  let(:canvas_client) { double(CanvasAPI) }


  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # CourseCustomContentVersionsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  before(:each) do
    allow(CanvasAPI).to receive(:client).and_return(canvas_client)
  end

  context 'when logged in as admin user' do
    before do
      sign_in admin_user
    end  

    describe "GET #new" do

      context 'for project' do
        let!(:new_project) { create :project }

        before(:each) do
          allow(canvas_client).to receive(:get_rubrics).with(course.canvas_course_id, true).and_return([
            CanvasAPI::LMSRubric.new(canvas_new_rubric['id'], canvas_new_rubric['title'])
          ])
        end

        it 'returns a success response' do
          get :new, params: valid_project_params, session: valid_session
          expect(response).to be_successful
        end

        it 'excludes already published projects' do
          get :new, params: valid_project_params, session: valid_session
          expect(response.body).to match /<option value="#{new_project.id}">#{new_project.title}<\/option>/
          expect(response.body).not_to match /<option.*>#{project.title}<\/option>/
        end

        it 'sets the rubrics list' do
          response = get :new, params: valid_project_params, session: valid_session
          expect(response.body).to match /<option value="#{canvas_new_rubric['id']}">#{canvas_new_rubric['title']}<\/option>/
        end

        it 'excludes rubrics already associated with an assignment from the list' do
          expect(canvas_client).to receive(:get_rubrics).with(course.canvas_course_id, true).once
          response = get :new, params: valid_project_params, session: valid_session
        end
        
      end

      context 'for survey' do
        it 'returns a success response' do
          get :new, params: valid_survey_params, session: valid_session
          expect(response).to be_successful
        end

        it 'doesnt set the rubrics list' do
          expect(canvas_client).not_to receive(:get_rubrics)
          expect(canvas_client).not_to receive(:get_assignments)
          response = get :new, params: valid_survey_params, session: valid_session
        end
      end
    end

    describe 'POST #create' do

      context 'with valid params' do

        context 'for project' do
          let(:valid_project_create_params) { {course_id: course.id, custom_content_id: project.id, type: 'CourseProjectVersion'} }
          let(:name) { 'Test Create Project 1' }
          let(:created_canvas_assignment) { build(:canvas_assignment, course_id: course['canvas_course_id'], name: name) }
          let(:created_cccv) { CourseProjectVersion.last }
  
          before(:each) do
            allow(canvas_client).to receive(:create_lti_assignment).and_return(created_canvas_assignment)
            allow(canvas_client).to receive(:update_assignment_lti_launch_url)
            allow(canvas_client).to receive(:add_rubric_to_assignment)
          end

          it 'creates the Canvas assignment' do
            expect(canvas_client).to receive(:create_lti_assignment)
              .with(course.canvas_course_id, project.title)
            post :create, params: valid_project_create_params, session: valid_session
          end

          it 'saves a new version of the project' do
            expect { post :create, params: valid_project_create_params, session: valid_session }.to change {ProjectVersion.count}.by(1)
          end

          it 'creates a new CourseProjectVersion for the new content version' do
            expect { post :create, params: valid_project_create_params, session: valid_session }.to change {CourseProjectVersion.count}.by(1)
            expect(created_cccv.custom_content_version).to eq(ProjectVersion.last)
          end

          it 'sets the LTI launch URL to the proper project submission URL' do
            post :create, params: valid_project_create_params, session: valid_session
            expect(canvas_client).to have_received(:update_assignment_lti_launch_url)
              .with(
                course['canvas_course_id'],
                created_canvas_assignment['id'],
                created_cccv.new_submission_url,
              )
              .once
          end

          it 'redirects back to edit page and flashes message' do
            response = post :create, params: valid_project_create_params, session: valid_session
            expect(response).to redirect_to(edit_course_path(course_project_version.course))
            expect(flash[:notice]).to match /successfully published/
          end

          context 'with rubric' do
            let(:projet_create_params_with_rubric) { {course_id: course.id, custom_content_id: project.id, rubric_id: canvas_new_rubric['id'], type: 'CourseProjectVersion'} }

            it 'associates the rubric with the project in Canvas' do
              response = post :create, params: projet_create_params_with_rubric, session: valid_session
              expect(canvas_client).to have_received(:add_rubric_to_assignment)
                .with(course['canvas_course_id'], created_canvas_assignment['id'], canvas_new_rubric['id'].to_s).once
            end
          end
        end
      end

      context 'with invalid params' do
        let(:course_launched) { create :course_launched }
        it 'throws when Course is already launched' do
          expect { post :create, params: {course_id: course_launched.id, custom_content_id: project.id}, session: valid_session }
            .to raise_error(Course::CourseEditError)
        end
      end
    end # 'POST #create'

    describe 'POST #update' do
      context 'with valid params' do

        context 'for project' do
          let(:new_body) { 'updated project body' }

          before(:each) do
            allow(canvas_client).to receive(:get_assignment)
            project = course_project_version.project_version.project
            project.body = new_body
            project.save!
          end

          it 'saves a new version of the project' do
            expect { post :update, params: valid_project_params, session: valid_session }.to change {ProjectVersion.count}.by(1)
          end

          it 'associates the exsiting CourseProjectVersion to the new content version' do
            expect(course_project_version.project_version.body).not_to eq(new_body)
            expect { post :update, params: valid_project_params, session: valid_session }.not_to change {CourseProjectVersion.count}
            expect(CourseProjectVersion.find(course_project_version.id).custom_content_version).to eq(ProjectVersion.last)
          end

          it 'redirects back to edit page and flashes message' do
            response = post :update, params: valid_project_params, session: valid_session
            expect(response).to redirect_to(edit_course_path(course_project_version.course))
            expect(flash[:notice]).to match /successfully published/
          end
        end
      end

      context 'with invalid params' do
        let(:course_launched) { create :course_launched }
        let(:launched_course_project_params) { {course_id: course_launched.id, id: course_project_version, type: 'CourseProjectVersion' } }

        it 'throws when Course is already launched' do
          expect { post :update, params: launched_course_project_params, session: valid_session }.to raise_error(Course::CourseEditError)
        end
      end
    end # 'POST #update'

    describe 'POST #delete' do
      context 'with valid params' do

        context 'for project' do

          before(:each) do
            allow(canvas_client).to receive(:delete_assignment)
            course_project_version # create it in the DB ahead of time
          end

          it 'doesnt delete the project version content' do
            expect { post :destroy, params: valid_project_params, session: valid_session }.not_to change {ProjectVersion.count}
          end

          it 'deletes the CourseProjectVersion join record' do
            expect { post :destroy, params: valid_project_params, session: valid_session }.to change {CourseProjectVersion.count}.by(-1)
            expect { CourseProjectVersion.find(course_project_version.id) }.to raise_error(ActiveRecord::RecordNotFound)
          end

          it 'deletes the Canvas assignment' do
            expect(canvas_client).to receive(:delete_assignment)
              .with(course_project_version.course.canvas_course_id,
                    course_project_version.canvas_assignment_id)
            post :destroy, params: valid_project_params, session: valid_session
          end

          it 'doesnt delete the CourseProjectVersion if Canvas assignment deletion fails' do
            allow(canvas_client).to receive(:delete_assignment).and_raise RestClient::BadRequest
            expect { post :destroy, params: valid_project_params, session: valid_session }.to raise_error(RestClient::BadRequest)
            expect(CourseProjectVersion.find(course_project_version.id)).to be_present
          end

          it 'redirects back to edit page and flashes message' do
            response = post :destroy, params: valid_project_params, session: valid_session
            expect(response).to redirect_to(edit_course_path(course_project_version.course))
            expect(flash[:notice]).to match /successfully deleted/
          end
        end
      end

      context 'with invalid params' do
        let(:course_launched) { create :course_launched }
        let(:launched_course_project_params) { {course_id: course_launched.id, id: course_project_version, type: 'CourseProjectVersion' } }

        it 'throws when Course is already launched' do
          expect { post :destroy, params: launched_course_project_params, session: valid_session }.to raise_error(Course::CourseEditError)
        end
      end
    end # 'POST #delete

  end # logged in as admin user
end
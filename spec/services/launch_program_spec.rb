# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LaunchProgram do
  let(:sf_program_id) { 'TestSalesforceProgramID' }
  let(:fellow_course_name) { 'Test Fellow Course Name' }
  let(:fellow_course_template) { create(:course_template, attributes_for(:course_template_with_resource)) }
  let(:lc_course_template) { create(:course_template_with_canvas_id) }
  let(:lc_course_name) { 'Test LC Course Name' }
  let(:new_fellow_course_id) { 93487 }
  let(:new_lc_course_id) { 93488 }
  let(:canvas_create_fellow_course) { build(:canvas_course, id: new_fellow_course_id) }
  let(:canvas_create_lc_course) { build(:canvas_course, id: new_lc_course_id) }
  let(:canvas_copy_fellow_course) { build(:canvas_content_migration, source_course_id: fellow_course_template.canvas_course_id) }
  let(:canvas_copy_lc_course) { build(:canvas_content_migration, source_course_id: lc_course_template.canvas_course_id) }
  let(:canvas_client) { double(CanvasAPI) }
  let(:salesforce_program) { build(:salesforce_program_record) }
  let(:fellow_section_names) { [] }
  let(:sf_api_client) { SalesforceAPI.new }

  before(:each) do
    allow(LaunchProgram).to receive(:sleep).and_return(nil)
    allow(CanvasAPI).to receive(:client).and_return(canvas_client)
    allow(canvas_client).to receive(:create_course).with(fellow_course_name).and_return(canvas_create_fellow_course)
    allow(canvas_client).to receive(:copy_course).with(fellow_course_template.canvas_course_id, new_fellow_course_id).and_return(canvas_copy_fellow_course)
    allow(canvas_client).to receive(:create_course).with(lc_course_name).and_return(canvas_create_lc_course)
    allow(canvas_client).to receive(:copy_course).with(lc_course_template.canvas_course_id, new_lc_course_id).and_return(canvas_copy_lc_course)
    allow(sf_api_client).to receive(:get_program_info).and_return(salesforce_program)
    allow(sf_api_client).to receive(:get_cohort_schedule_section_names).and_return(fellow_section_names)
    allow(SalesforceAPI).to receive(:client).and_return(sf_api_client)
  end

  subject(:launch_program) do
    LaunchProgram.new(sf_program_id, fellow_course_template.id, fellow_course_name, lc_course_template.id, lc_course_name)
  end

  describe '#initialize' do

    context 'with valid Program' do
      let(:fellow_section_names) { [ 'Test CohortSchedule 1', 'Test CohortSchedule 2' ] }

      it "doesn't raise error" do
        expect { launch_program }.not_to raise_error
      end
    end
    
    context 'with invalid Program' do
      it "raises error with bad Program ID" do
        allow(sf_api_client).to receive(:get_program_info).and_raise RestClient::BadRequest
        expect { launch_program }.to raise_error(RestClient::BadRequest)
      end

      it "raises an error when missing 'Section Name in LMS Coach Course' field" do
        salesforce_program['Section_Name_in_LMS_Coach_Course__c'] = nil
        expect { launch_program }.to raise_error(LaunchProgram::LaunchProgramError).with_message(/Section Name in LMS/)
      end

      it "raises an error when missing Cohort Schedules" do
        expect { launch_program }.to raise_error(LaunchProgram::LaunchProgramError).with_message(/No Cohort Schedules/)
      end
    end
  end

  describe '#run' do
    let(:fellow_section_names) { [ 'Test CohortSchedule 1', 'Test CohortSchedule 2' ] }
    let(:canvas_sections) { [] }

    # TODO: the LC course shouldn't return these.
    let(:assignment1) { build(:canvas_assignment, course_id: new_fellow_course_id) }
    let(:assignment2) { build(:canvas_assignment, course_id: new_fellow_course_id) }
    let(:assignments) { [assignment1, assignment2] }
    let(:copy_progress_running) { build(:canvas_progress, workflow_state: 'running') }
    let(:copy_progress_complete) { build(:canvas_progress, workflow_state: 'completed') }

    before(:each) do
      allow(canvas_client).to receive(:get_copy_course_status)
        .and_return(copy_progress_running, copy_progress_complete, copy_progress_running, copy_progress_complete)
      allow(canvas_client).to receive(:create_lms_section) { |course_id:, name:| 
        new_section = build(:canvas_section)
        canvas_sections << new_section
        CanvasAPI::LMSSection.new(new_section['id'], name)
      }
      allow(canvas_client).to receive(:get_assignments).and_return(assignments) 
      allow(canvas_client).to receive(:update_assignment_lti_launch_url)
      allow(canvas_client).to receive(:create_assignment_overrides)
    end

    context "with Canvas API success" do
      it "calls canvas API to copy both fellow and LC courses" do
        expect(canvas_client).to receive(:create_course).with(fellow_course_name).once
        expect(canvas_client).to receive(:create_course).with(lc_course_name).once
        expect(canvas_client).to receive(:copy_course).with(fellow_course_template.canvas_course_id, canvas_create_fellow_course['id']).once
        expect(canvas_client).to receive(:copy_course).with(lc_course_template.canvas_course_id, canvas_create_lc_course['id']).once
        launch_program.run
      end

      it "creates new Courses in local database" do
        expect { launch_program.run }.to change(Course, :count).by(2)
        fellow_course = Course.find_by(name: fellow_course_name)
        expect(fellow_course.canvas_course_id).to eq canvas_create_fellow_course['id']
        expect(fellow_course.course_resource_id).to eq fellow_course_template.course_resource_id
        lc_course = Course.find_by(name: lc_course_name)
        expect(lc_course.canvas_course_id).to eq canvas_create_lc_course['id']
        expect(lc_course.course_resource_id).to eq lc_course_template.course_resource_id
      end

      it "waits for the Canvas course copy to finish before getting assignments" do
        # twice for the Fellow course and twice for LC course
        expect(canvas_client).to receive(:get_copy_course_status).with(canvas_copy_fellow_course['progress_url']).exactly(2).times
        expect(canvas_client).to receive(:get_copy_course_status).with(canvas_copy_lc_course['progress_url']).exactly(2).times
        launch_program.run
      end

      it "creates the Canvas sections" do
        expect(canvas_client).to receive(:create_lms_section).with(course_id: new_fellow_course_id, name: fellow_section_names[0]).once
        expect(canvas_client).to receive(:create_lms_section).with(course_id: new_fellow_course_id, name: fellow_section_names[1]).once
        expect(canvas_client).to receive(:create_lms_section).with(course_id: new_lc_course_id, name: salesforce_program['Section_Name_in_LMS_Coach_Course__c']).once
        launch_program.run
      end

      it "sets the AssignmentOverrides" do
        launch_program.run
        expect(canvas_client).to have_received(:create_assignment_overrides)
          .with(new_fellow_course_id, [assignment1['id'], assignment2['id']], [canvas_sections[0]['id'], canvas_sections[1]['id']]).once
      end

      context "adjusts LTI launch URLs" do

        let(:course_project_version_template) { create(:course_project_version, base_course: fellow_course_template) } 
        let(:lti_launch_url_project_template) { "https://platformweb/base_course_custom_content_versions/#{course_project_version_template.id}/submissions/new" }
        # This mimics an assignment that was cloned to the new course with the old launch URL for the template
        let(:assignment_needing_launch_url_update1) { build(:canvas_assignment, course_id: new_fellow_course_id, lti_launch_url: lti_launch_url_project_template) }

        xit "calls CanvasAPI.update_assignment_lti_launch_url() with the proper arguments" do
          # TODO: setup an LTI assignment on the fellow template. Setup a different one with the same base_course_custom_content_versions.id
          # on the copied course. Make sure a call to the CanvasAPI to update the copied course Canva assigment's LTI launch URL from the old
          #  URL to a new URL for a new base_course_custom_content_versions record inserted that maps the newly copied assignment to the same
          # custom_contents_version. See: https://app.asana.com/0/1174274412967132/1198900743766613
          allow(canvas_client).to receive(:get_assignments).and_return([assignment_needing_launch_url_update1])
          launch_program.run
          expect(canvas_client).to have_received(:update_assignment_lti_launch_url).with(course_id: new_fellow_course_id, assignment_id: fellow_assignment1['id'], new_url: "TODO").once
        end
      end

    end

    context "with Canvas API failure" do
      it "raises an exception" do
        allow(canvas_client).to receive(:copy_course).and_raise(RestClient::NotFound)
        expect { launch_program.run }.to raise_error(RestClient::NotFound)
      end
    end
  end

end

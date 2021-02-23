# frozen_string_literal: true
require 'canvas_api'

# Responsible for fetching all assignments for a Canvas course
# and making information about them available. Intended for
# Course Management tools.
class FetchCanvasAssignmentsInfo
  FetchCanvasAssignmentsInfoError = Class.new(StandardError)

  include Rails.application.routes.url_helpers

  attr_reader :canvas_assignment_ids,
              :canvas_waivers_url, :canvas_waivers_assignment_id,
              :canvas_preaccelerator_survey_url, :canvas_preaccelerator_survey_assignment_id,
              :canvas_postaccelerator_survey_url, :canvas_postaccelerator_survey_assignment_id,
              :canvas_peer_reviews_url, :canvas_peer_reviews_assignment_id,
              :canvas_peer_review_results_url, :canvas_peer_review_results_assignment_id,
              :canvas_fellow_evaluation_url, :canvas_fellow_evaluation_assignment_id,
              :course_project_versions, :course_survey_versions,
              :course_custom_content_versions_mapping,  # Maps the fetched canvas assignment ID to the cccv.
              :course_attendance_events_mapping,
              :rise360_module_versions_mapping

  def initialize(canvas_course_id)
    @canvas_course_id = canvas_course_id
    @canvas_assignment_ids = nil

    @canvas_waivers_url  = nil
    @canvas_waivers_assignment_id = nil
    
    @canvas_preaccelerator_survey_url = nil
    @canvas_preaccelerator_survey_assignment_id  = nil

    @canvas_postaccelerator_survey_url = nil
    @canvas_postaccelerator_survey_assignment_id  = nil

    @canvas_peer_reviews_url = nil
    @canvas_peer_reviews_assignment_id = nil

    @canvas_peer_review_results_url = nil
    @canvas_peer_review_results_assignment_id = nil

    @canvas_fellow_evaluation_url = nil
    @canvas_fellow_evaluation_assignment_id = nil

    @course_project_versions = nil
    @course_survey_versions = nil
    @course_custom_content_versions_mapping = nil

    @course_attendance_events_mapping = nil

    @rise360_module_versions_mapping = nil

    # Add the rest of the assignment types we implement as well. E.g. pre/post
    # accelerator surveys, peer evaluations, attendance, etc
  end

  def run
    canvas_assignments = CanvasAPI.client.get_assignments(@canvas_course_id)

    @canvas_assignment_ids = []
    @course_project_versions= []
    @course_survey_versions = []
    @course_custom_content_versions_mapping = {}
    @course_attendance_events_mapping = {}
    @rise360_module_versions_mapping = {}

    canvas_assignments.each do |ca|
      @canvas_assignment_ids << ca['id']

      lti_launch_url = parse_lti_launch_url(ca)
      if lti_launch_url
        parse_assignment_info!(lti_launch_url, ca)
      else
        # Not an assignment published with an LTI submission type. We don't care
        # about any of those at the moment but we may in the future.
      end
    end

    self 
  end

private

  def parse_lti_launch_url(canvas_assignment)
    canvas_assignment.dig('external_tool_tag_attributes', 'url')
  end

  def parse_assignment_info!(lti_launch_url, canvas_assignment)
    cccv = CourseCustomContentVersion.find_by_lti_launch_url(lti_launch_url) 
    add_project_or_survey_info!(cccv, canvas_assignment) and return if cccv

    rise360_module_version = Rise360ModuleVersion.find_by_lti_launch_url(lti_launch_url)
    add_module_info(rise360_module_version, canvas_assignment) and return if rise360_module_version

    # Doesn't matter which Course the CourseAttendanceEvent is attached to, because we'll be
    # replacing the course. Just get one with the right AttendanceEvent.
    attendance_event_submission_answer_path = launch_attendance_event_submission_answers_path
    if lti_launch_url =~ /#{attendance_event_submission_answer_path}/
      attendance_event = AttendanceEvent.find_by(title: canvas_assignment['name'])
      course_attendance_event = CourseAttendanceEvent.find_by(attendance_event_id: attendance_event&.id)
      add_attendance_event_info(course_attendance_event, canvas_assignment)
      return
    end

    # We don't use new_**course**_peer_review_submission_path here because
    # InitializeNewCourse needs to be able to detect the LTI launch URL that
    # was copied containing the old course ID
    peer_review_submission_path = 'peer_review_submissions/new'
    add_peer_review_info(canvas_assignment) and return if lti_launch_url =~ /#{peer_review_submission_path}/

    peer_review_result_path = launch_peer_review_results_path
    add_peer_review_result_info(canvas_assignment) and return if lti_launch_url =~ /#{peer_review_result_path}/

    fellow_evaluation_submission_path = 'fellow_evaluation_submissions/new'
    add_fellow_evaluation_info(canvas_assignment) and return if lti_launch_url =~ /#{fellow_evaluation_submission_path}/

    waivers_launch_path = launch_waiver_submissions_path
    add_waivers_info(canvas_assignment) and return if lti_launch_url =~ /#{waivers_launch_path}/

    preaccelerator_survey_submission_path = launch_preaccelerator_survey_submissions_path
    add_preaccelerator_survey_info(canvas_assignment) and return if lti_launch_url =~ /#{preaccelerator_survey_submission_path}/

    postaccelerator_survey_submission_path = launch_postaccelerator_survey_submissions_path
    add_postaccelerator_survey_info(canvas_assignment) and return if lti_launch_url =~ /#{postaccelerator_survey_submission_path}/

  end

  def add_project_or_survey_info!(course_custom_content_version, canvas_assignment)
    if course_custom_content_version.is_a?(CourseProjectVersion)
      @course_project_versions << course_custom_content_version
    elsif course_custom_content_version.is_a?(CourseSurveyVersion)
      @course_survey_versions << course_custom_content_version
    else
      raise FetchCanvasAssignmentsInfoError, "CourseCustomContentVersion type not recognized: #{course_custom_content_version.inspect}"
    end

    @course_custom_content_versions_mapping[canvas_assignment['id']] = course_custom_content_version
  end

  def add_module_info(rise360_module_version, canvas_assignment)
    @rise360_module_versions_mapping[canvas_assignment['id']] = rise360_module_version
  end

  def add_attendance_event_info(course_attendance_event, canvas_assignment)
    @course_attendance_events_mapping[canvas_assignment['id']] = course_attendance_event
  end

  def add_waivers_info(canvas_assignment)
    if @canvas_waivers_url
      raise FetchCanvasAssignmentsInfoError, "Second assignment with Waivers found. First[#{@canvas_waivers_url}]. Second[#{canvas_assignment['html_url']}]"
    else
      @canvas_waivers_url = canvas_assignment['html_url']
      @canvas_waivers_assignment_id = canvas_assignment['id']
    end
  end

  def add_peer_review_info(canvas_assignment)
    if @canvas_peer_reviews_url
      raise FetchCanvasAssignmentsInfoError, "Duplicate Peer Reviews assignment found."\
        "First[#{@canvas_peer_reviews_url}]. "\
        "Second[#{canvas_assignment['html_url']}]."
    end
    @canvas_peer_reviews_url = canvas_assignment['html_url']
    @canvas_peer_reviews_assignment_id = canvas_assignment['id']
  end

  def add_peer_review_result_info(canvas_assignment)
    if @canvas_peer_review_results_url
      raise FetchCanvasAssignmentsInfoError, "Duplicate Peer Review Results assignment found."\
        "First[#{@canvas_peer_review_results_url}]. "\
        "Second[#{canvas_assignment['html_url']}]."
    end
    @canvas_peer_review_results_url = canvas_assignment['html_url']
    @canvas_peer_review_results_assignment_id = canvas_assignment['id']
  end

  def add_fellow_evaluation_info(canvas_assignment)
    if @canvas_fellow_evaluation_url
      raise FetchCanvasAssignmentsInfoError, "Duplicate Fellow Evaluation assignment found."\
        "First[#{@canvas_fellow_evaluation_url}]. "\
        "Second[#{canvas_assignment['html_url']}]."
    end
    @canvas_fellow_evaluation_url = canvas_assignment['html_url']
    @canvas_fellow_evaluation_assignment_id = canvas_assignment['id']
  end

  def add_preaccelerator_survey_info(canvas_assignment)
    if @canvas_preaccelerator_survey_url
      raise FetchCanvasAssignmentsInfoError, "Duplicate Pre-Accelerator Survey assignment found."\
        "First[#{@canvas_preaccelerator_survey_url}]. "\
        "Second[#{canvas_assignment['html_url']}]."
    end
    @canvas_preaccelerator_survey_url = canvas_assignment['html_url']
    @canvas_preaccelerator_survey_assignment_id = canvas_assignment['id']
  end

  def add_postaccelerator_survey_info(canvas_assignment)
    if @canvas_postaccelerator_survey_url
      raise FetchCanvasAssignmentsInfoError, "Duplicate Post-Accelerator Survey assignment found."\
        "First[#{@canvas_postaccelerator_survey_url}]. "\
        "Second[#{canvas_assignment['html_url']}]."
    end
    @canvas_postaccelerator_survey_url = canvas_assignment['html_url']
    @canvas_postaccelerator_survey_assignment_id = canvas_assignment['id']
  end
end

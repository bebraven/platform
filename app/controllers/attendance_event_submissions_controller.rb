# frozen_string_literal: true

require 'attendance_grade_calculator'
require 'canvas_api'
require 'salesforce_api'

# This controller handles the "Take Attendance" link that Leadership Coaches
# see in the LC Playbook course.
# We assume that the `current_user` is an LC and @course is the LC Playbook
# course that they are enrolled in as a student.
# We also assume the LC is enrolled in the appropriate Accelerator course
# as a TA.
#
# It is responsible for submitted a set of "answers", one per Fellow, that
# represents their attendance for an event.
class AttendanceEventSubmissionsController < ApplicationController
  include DryCrud::Controllers
  include LtiHelper

  before_action :set_lti_launch, only: [:launch, :edit, :update, :answers]
  before_action :set_accelerator_course, only: [:launch, :edit, :update]
  before_action :set_course_attendance_event, only: [:launch]
  before_action :set_fellow_users, only: [:edit, :update]
  skip_before_action :verify_authenticity_token, only: [:update], if: :is_sessionless_lti_launch?

  layout 'lti_canvas'

  # Note: This is a non-standard action. It is used by the "Take Attendance"
  # links in the LC Playbook course.
  def launch
    respond_to do |format|
      format.html do
        if @course_attendance_event.nil?
          authorize @accelerator_course, policy_class: AttendanceEventSubmissionPolicy
          Honeycomb.add_field('attendance.no.events', true)
          logger.warn("User #{current_user} is trying to take attendance but there are no events " \
                      "in the Accelerator course '#{@accelerator_course.inspect}'")
          render :no_course_attendance_events and return
        end

        if sections_as_ta.count != 1 and not current_user.admin?
          authorize @accelerator_course, policy_class: AttendanceEventSubmissionPolicy
          Honeycomb.add_field('attendance.mulitple.sections', true)
          logger.error("User #{current_user} is a TA in multiple sections. Cannot take attendance.")
          render :multiple_sections and return
        end
        # This is a find_or_new_by() so we have an object to authorize against
        @attendance_event_submission = AttendanceEventSubmission.find_by(
          user: current_user,
          course_attendance_event: @course_attendance_event,
        ) || AttendanceEventSubmission.new(
          user: current_user,
          course_attendance_event: @course_attendance_event,
        )
        authorize @attendance_event_submission
        @attendance_event_submission.save! # Do this after the authorization so we don't add an unauthorized .new record
        redirect_to edit_attendance_event_submission_path(
          @attendance_event_submission,
          section_id: section.id,
          state: @lti_launch.state,
        )
      end
      format.json do
        authorize @accelerator_course, policy_class: AttendanceEventSubmissionPolicy
        params.require(:course_attendance_event_id)
        render json: AttendanceEventSubmission.find_by(
          user: current_user,
          course_attendance_event: @course_attendance_event,
        )
      end
    end
  end

  def answers
    params.require(:section_id)

    @attendance_event_submission = AttendanceEventSubmission.find(params[:id])
    authorize @attendance_event_submission

    render json: Section.find(params[:section_id]).students.map {
      |student| { for_user_name: student.full_name }.merge(
        @attendance_event_submission.answers.find_by(for_user_id: student.id)&.as_json || {}
      )
    }
  end

  def edit
    authorize @attendance_event_submission
    @course_attendance_events = @attendance_event_submission
      .course
      .course_attendance_events
      .order_by_title
      .map { |cae| { id: cae.id, title: cae.attendance_event.title } }
    @section = section
  end

  def update
    authorize @attendance_event_submission

    # Save attendance to our DB
    @attendance_event_submission.save_answers!(
      attendance_status_by_user_hash,
      current_user,
    )

    # Update Fellow grades in Canvas
    CanvasAPI.client.update_grades(
      @accelerator_course.canvas_course_id,
      @attendance_event_submission.course_attendance_event.canvas_assignment_id,
      AttendanceGradeCalculator.compute_grades(@attendance_event_submission),
    )

    title = @attendance_event_submission.course_attendance_event.attendance_event.title
    respond_to do |format|
      format.html { redirect_to(
        edit_attendance_event_submission_path(
          @attendance_event_submission,
          state: @lti_launch.state,
        ),
        notice: "Attendance for #{title} saved."
      ) }
      format.json { head :no_content }
    end
  end

private
  # For #launch, #edit, #update
  def set_accelerator_course
    return if @accelerator_course

    # Get this course, the LC Playbook course, from the LTI launch
    lc_playbook_course = Course.find_by(
      canvas_course_id: @lti_launch.request_message.canvas_course_id,
    )

    # Figure out the Accelerator course using Salesforce
    accelerator_canvas_course_id = SalesforceAPI.client.get_accelerator_course_id_from_lc_playbook_course_id(
      lc_playbook_course.canvas_course_id,
    )

    @accelerator_course = Course.find_by(canvas_course_id: accelerator_canvas_course_id)
  end

  # For #launch
  def set_course_attendance_event
    if params[:course_attendance_event_id]
      @course_attendance_event = @accelerator_course.course_attendance_events.find(
        params[:course_attendance_event_id],
      )
    else
      @course_attendance_event = helpers.get_default_course_attendance_event(section)
    end
  end

  # For #edit, #update
  def set_fellow_users
    # Get all users enrolled as students in the section.
    # Note this is implicitly limited to students in this course and further
    # restricted so only people with special permission can see students in
    # sections they're not the TA for, by the `section` call. If you refactor
    # this, be sure to keep those limitations.
    @fellow_users = []
    @fellow_users = section.students if section
  end

  def section
    # If we have special permission, try to use the section_id param.
    # Fall back to first section as TA, then first section in the course (if not a TA).
    if current_user.can_take_attendance_for_all?
      return @accelerator_course.sections.find_by_id(params[:section_id]) || sections_as_ta.first || @accelerator_course.sections.first
    end

    # If no special permission, fall back to TA section.
    # At the moment we only expect a Leadership Coach to be in one section
    # and show an error page if that's not true.
    sections_as_ta.first
  end

  # Get all Accelerator course sections where this user is a TA.
  def sections_as_ta
    @sections_as_ta ||= current_user
      .sections_with_role(RoleConstants::TA_ENROLLMENT)
      .select { |section| section.course_id == @accelerator_course.id}
  end

  # For #update
  def attendance_status_by_user_hash
    attendance_event_submission_param = params.require(:attendance_event_submission)
    attendance_event_submission_param.permit!.to_h.filter do |user_id|
      # Restrict to only users in the section, which we have already determined
      # current_user is allowed to access.
      @fellow_users.any? { |user| user.id.to_s == user_id.to_s }
    end
  end
end

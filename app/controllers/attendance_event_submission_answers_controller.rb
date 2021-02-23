# frozen_string_literal: true

# Represents the attendance answer (aka attendance status) submitted for a
# Fellow (student) for a given event (e.g. a Learning Lab). An
# AttendanceEventSubmission is a set of answers, one per Fellow. 
#
# Note: we use "answer" to be consistent with the other submission controllers/models.
class AttendanceEventSubmissionAnswersController < ApplicationController
  include DryCrud::Controllers
  
  # For the #launch action
  include LtiHelper
  before_action :set_lti_launch, only: [:launch]
  before_action :set_course_attendance_event, only: [:launch]

  layout 'lti_canvas'

  def launch
    authorize @course_attendance_event, :launch?
    @attendance_event = @course_attendance_event.attendance_event
  end

private
  # For #launch
  def set_course_attendance_event
    @course_attendance_event = CourseAttendanceEvent.find_by(
      canvas_assignment_id: @lti_launch.request_message.custom['assignment_id'],
    )
  end
end

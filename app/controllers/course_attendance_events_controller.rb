# frozen_string_literal: true

class CourseAttendanceEventsController < ApplicationController
  include DryCrud::Controllers::Nestable
  nested_resource_of Course

  # Adds the #publish, #unpublish actions
  include Publishable
  prepend_before_action :set_model_instance, only: [:unpublish]

  layout 'admin'

  def new
    authorize CourseAttendanceEvent
    @attendance_events = AttendanceEvent.all - @course.attendance_events
  end

private
  # For Publishable
  def assignment_name
    @course_attendance_event.attendance_event.title
  end

  def lti_launch_url
    launch_attendance_event_submissions_url(protocol: 'https')
  end

  # Note: The versioning here is faked by AttendanceEvent
  def versionable_instance
    AttendanceEvent.find(params[:attendance_event_id])
  end

  def version_name
    'attendance_event'
  end
end

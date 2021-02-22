# frozen_string_literal: true

module Api
  class CourseAttendanceEventsController < ApplicationController
    include DryCrud::Controllers::Nestable
    nested_resource_of Course

    # GET course/{course_id}/course_attendance_events
    def index
      authorize CourseAttendanceEvent
      course_attendance_events = @course.course_attendance_events.order_by_title
      render json: course_attendance_events.map { |cae| cae.attendance_event }
    end
  end
end

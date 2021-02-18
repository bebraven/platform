# frozen_string_literal: true

module Api
  class CourseAttendanceEventsController < ApplicationController
    include DryCrud::Controllers::Nestable
    nested_resource_of Course

    # GET course/{course_id}/course_attendance_events
    def index
      authorize CourseAttendanceEvent
      render json: @course.attendance_events
    end
  end
end

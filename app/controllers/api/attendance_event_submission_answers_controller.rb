# frozen_string_literal: true

module Api
  class AttendanceEventSubmissionAnswersController < ApplicationController
    include DryCrud::Controllers::Nestable
    nested_resource_of AttendanceEventSubmission

    # GET api/attendance_event_submissions/{id}/answers
    def index
      authorize @attendance_event_submission
      render json: @attendance_event_submission.answers
    end
  end
end

# frozen_string_literal: true

module Api
  class CourseAttendanceSectionsController < ApplicationController
    include DryCrud::Controllers::Nestable
    nested_resource_of Course

    # GET courses/{course_id}/attendance_sections
    def index
      authorize Course

      course_attendance_sections = current_user
        .sections_with_role(RoleConstants::TA_ENROLLMENT)
        .select { |section| section.course_id == @course.id && section.name != SectionConstants::TA_SECTION }

      render json: course_attendance_sections
    end
  end
end

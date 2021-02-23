class PeerReviewResultsController < ApplicationController
  include DryCrud::Controllers::Nestable
  
  layout 'lti_canvas'

  nested_resource_of Course

  before_action :set_peer_results, only: [:show]

  def launch
  end

  def show
  end

private
  def set_peer_results
    # Get the section in this course that the user is enrolled in as a student
    student_section = current_user.student_section_by_course(@course)
    if student_section&.students
      # You're enrolled as a student and there are other students in this course
      @peer_users = student_section.students.where.not(id: current_user.id)
    else
      # You're not enrolled as a student e.g., you're a TA or admin, or there
      # are no other students in this course
      @peer_users = []
    end
  end
end

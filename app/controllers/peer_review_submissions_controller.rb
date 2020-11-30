class PeerReviewSubmissionsController < ApplicationController
  include DryCrud::Controllers::Nestable
  # Controller actions are defined in Submittable.
  include Submittable
  
  layout 'lti_canvas'

  nested_resource_of Course

  before_action :set_peer_users, only: [:new, :create]
  before_action :set_questions, only: [:new, :create]

private

  def set_peer_users
    section = current_user.student_section_by_course(@course)
    @peer_users = section.students.where.not(id: current_user.id)
  end

  def set_questions
    @questions = PeerReviewQuestion.all
  end

  # Called by Submittable.create.
  def answers_params_hash
    peer_review_params = params.require(:peer_review)
    # Only allow submitting peer reviews for actual peers.
    peer_review_params.permit!.to_h.filter do |user_id|
      @peer_users.where(id: user_id).exists?
    end
  end
end

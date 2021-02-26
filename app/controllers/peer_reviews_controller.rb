# frozen_string_literal: true

class PeerReviewsController < ApplicationController
  include DryCrud::Controllers::Nestable

  # Adds the #publish and #unpublish actions
  include Publishable

  layout 'admin'

  nested_resource_of Course

  # Note: make sure this matches the naming conventions we have for the Canvas
  # assignments. For the Capstone project we have:
  #  - GROUP PROJECT: Capstone Challenge
  #  - GROUP PROJECT: Capstone Challenge: Teamwork
  #  - GROUP PROJECT: Complete Peer Evaluations
  PEER_REVIEWS_ASSIGNMENT_NAME = 'GROUP PROJECT: Complete Peer Evaluations'
  PEER_REVIEW_RESULTS_ASSIGNMENT_NAME = 'GROUP PROJECT: Capstone Challenge: Teamwork'

  # Extend Publishable.publish with support for the peer eval results
  # assignment, where team score results are submitted as a grade.
  def publish
    authorize :PeerReview

    # Add the results assignment.
    assignment = CanvasAPI.client.create_lti_assignment(
      @course.canvas_course_id,
      PEER_REVIEW_RESULTS_ASSIGNMENT_NAME,
    )

    CanvasAPI.client.update_assignment_lti_launch_url(
      @course.canvas_course_id,
      assignment['id'],
      launch_peer_review_results_url(@course, protocol: 'https')
    )

    # Let Publishable do its stuff.
    super
  end

  # Admin-only, nested under course.
  def index
    @peer_review_submissions = all_peer_review_submissions
    # TODO: results policy
    authorize @peer_review_submissions

    render layout: 'admin'
  end

  # POST
  # Admin-only, nested under course.
  def score
    # TODO: results policy
    authorize all_peer_review_submissions

    transaction do
      all_peer_review_submissions.each do |submission|
        submission.update!(new: false)
      end
    end
  end

  # Not actions.
  def assignment_name
    PEER_REVIEWS_ASSIGNMENT_NAME
  end

  def lti_launch_url
    new_course_peer_review_submission_url(@course, protocol: 'https')
  end

private

  # Admin-only.
  def all_peer_review_submissions
    PeerReviewSubmission.where(
      course: @course,
    )
  end
end

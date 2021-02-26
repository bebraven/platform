class PeerReviewResultsController < ApplicationController
  include DryCrud::Controllers::Nestable
  
  layout 'lti_canvas'

  nested_resource_of Course

  before_action :set_course, only: [:launch]

  # Read from LTI payload, redirect to appropriate #show path.
  def launch
    authorize @peer_review_result

    redirect_to peer_review_results_path(@peer_review_result, state: @lti_launch.state) and return if @peer_review_result

    # TODO
    render plain: "No results yet"
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

  # Show results and score breakdown.
  def show
    # TODO: policy
    authorize peer_review_submissions
    @peer_review_submission_answers = peer_review_submission_answers

    # Initialize to zero.
    @question_scores = {}
    PeerReviewQuestion.all.each do |question|
      @question_scores[question.text] = 0.0
    end

    # Total by summation.
    @peer_review_submission_answers.each do |answer|
      @question_scores[answer.question.text] += answer.input_value.to_f
    end

    # Divide to get the mean.
    @question_scores.each do |k, v|
      # Note submission count is possible ONLY because of the uniqueness constraint on (user,course).
      @question_scores[k] = @question_scores[k] / peer_review_submissions.count
    end

    @total_score = @question_scores.map { |k, v| v }.sum / @question_scores.count
  end

private
  def set_course
    @course = Course.find_by!(canvas_course_id: @lti_launch.request_message.canvas_course_id)
  end

  # TODO: Need correct unique constraints on questions/answers.
  def peer_review_submissions
    PeerReviewSubmission.where(
      course: @course,
      new: false,
    )
  end

  # Admin-only.
  def all_peer_review_submissions
    PeerReviewSubmission.where(
      course: @course,
    )
  end

  def peer_review_submission_answers
    PeerReviewSubmissionAnswer.where(
      submission: peer_review_submissions,
      for_user: current_user,
    )
  end
end

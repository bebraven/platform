# "Submittable" behavior for controllers like SurveySubmissionsController
# and PeerReviewSubmissionsController.
#
# This concern heavily depends on DryCrud::Controllers::Nestable, and requires
# the including controller to be nested under one parent.
#
# Usage:
#
#   include DryCrud::Controllers::Nestable
#   include Submittable
#   nested_resource_of MyParentResource
#
# When using this concern, you must also define a method `answers_params_hash`
# in the including controller. For example:
#
#   def answers_params_hash
#     params.permit(:permitted_stuff).to_h
#   end
#
#   def allow_multiple_submissions
#     true
#   end
#
# The results of this hash are passed to MyModel.save_answers! in #create below.
# The model you're using the controller with must then implement `save_answers!`
# that takes in the answers_params_hash and saves the submission answers. Note
# that this concern doesn't care what the hash looks like, it just has to match
# what the model's `save_answers!` method accepts. For example, the answers hashes
# for SurveySubmission and PeerReviewSubmission look completely different.

require 'lti_advantage_api'
require 'lti_score'

module Submittable
  extend ActiveSupport::Concern
  include LtiHelper

  included do
    # Fail out early if something's wrong.
    error_msg = "Submittable depends on Nestable, but Nestable was not included"
    raise StandardError.new(error_msg) unless self.respond_to? 'nested_resource_of'

    prepend_before_action :set_lti_launch
    before_action :set_new_model_instance, only: [:new, :create]
    skip_before_action :verify_authenticity_token, only: [:create], if: :is_sessionless_lti_launch?
  end

  def show
    authorize instance_variable
  end

  def new
    authorize instance_variable

    return if allow_multiple_submissions

    # Only one submission per user and nest-parent.
    previous_submission = model_class.find_by(
      :user => current_user,
      parent_variable_name => instance_variable_get("@#{parent_variable_name}")
    )

    return redirect_to instance_path(previous_submission) if previous_submission
  end

  def create
    authorize instance_variable

    # Only one submission per user and nest-parent.
    previous_submission = model_class.find_by(
      :user => current_user,
      parent_variable_name.to_sym => instance_variable_get("@#{parent_variable_name}")
    )
    return redirect_to instance_path(previous_submission) if previous_submission

    # Record in our DB first, so we have the data even if updating Canvas fails.
    instance_variable.save_answers!(answers_params_hash)

    # Update Canvas
    lti_score = LtiScore.new_full_credit_submission(
      @current_user.canvas_user_id,
      # E.g. survey_submission_url(@survey_submission, protocol: 'https').
      self.send("#{instance_variable_name}_url", instance_variable, protocol: 'https'),
    )
    LtiAdvantageAPI.new(@lti_launch).create_score(lti_score)

    redirect_to instance_path(instance_variable)
  end

private
  def instance_variable
    instance_variable_get("@#{instance_variable_name}")
  end

  # E.g. course.
  def parent_variable_name
    @parent.class.name.underscore
  end

  # E.g. peer_review_submission_path(instance, ...).
  def instance_path(instance)
    self.send(
      "#{instance_variable_name}_path",
      instance,
      state: @lti_launch.state,
    )
  end

  def set_new_model_instance
    instance_variable_set("@#{instance_variable_name}", model_class.new(
      :user => current_user,
      @parent.class.name.underscore.to_sym => instance_variable_get("@#{@parent.class.name.underscore}")
    ))
  end
end

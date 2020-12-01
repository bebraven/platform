class SurveySubmissionsController < ApplicationController
  include DryCrud::Controllers::Nestable
  # Controller actions are defined in Submittable.
  include Submittable
  
  layout 'lti_canvas'

  nested_resource_of CourseSurveyVersion

private
  # Called by Submittable.new.  
  def allow_multiple_submissions
    false
  end

  # Called by Submittable.create.
  def answers_params_hash
    # Since this controller accepts arbitrary params to #create, explicitly remove
    # the params we know we don't want.
    params.except(
      :course_survey_version_id,
      :type,
      :controller,
      :action,
      :commit,
      :state,
      :authenticity_token,
    ).permit!.to_h
  end
end

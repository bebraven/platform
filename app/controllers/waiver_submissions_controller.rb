# frozen_string_literal: true

require 'form_assembly_api'
require 'lti_score'
require 'lti_advantage_api'

# Handles launching and submitting waivers that we require folks to sign in order to participate
# in the course. See WaiversController for more info about how these are published and how they're
# created and configured (FormAssembly).
class WaiverSubmissionsController < FormAssemblyController
  include Rails.application.routes.url_helpers

  attr_reader :base_course, :lti_launch

  before_action :set_lti_launch, only: [:new, :create, :launch]
  before_action :set_base_course, only: [:new, :create, :launch]
  before_action :set_new_waivers_url, only: [:launch]

  # Presents a page to launch the Waivers form in its own window (aka this window) instead of inside an iFrame where
  # the Waivers assignment is shown in Canvas.
  #
  # Note: ideally this would be nested under base_course similar to the rest of the routes, but it
  # means that we'd need to adjust the LtiLaunch URLs when we launch a new Program and the course id changes.
  # This way, it's just a static endpoint for any course to launch the waivers for that course pulling the
  # course info out of the LtiLaunch context.
  #
  # GET /waivers/launch
  def launch
    authorize :waiver_submission

    redirect_to completed_waiver_submissions_path if waivers_already_signed?
  end

  # Show the FormAssembly waiver form for them to sign.
  #
  # GET /waivers/new
  def new 
    authorize :waiver_submission

    # We just show a message about the Waivers only being loaded for a launched Course.
    render :new_for_course_template and return if @base_course.is_a?(CourseTemplate)

    if params[:tfa_next].present?
      @form_head, @form_body = FormAssemblyAPI.client
        .get_next_form_head_and_body(params[:tfa_next])
    else
      @form_head, @form_body = FormAssemblyAPI.client
        .get_form_head_and_body(form_assembly_info.waivers_form_id, participantId: form_assembly_info.participant_id)
    end

    setup_head()
    setup_body()
  end

  # Handle the submission of the FormAssembly waivers. This is configured in FormAssembly by
  # creating a "Post Redirect" Connector on the final form in the flow when the Waivers are considered
  # fully signed. Under where the Connector says:
  #     "Posts submitted data back to a third-party script. Users are redirected to this script."
  # Add the URL for this action in the "Remote Script" field.
  #
  # See: https://help.formassembly.com/help/post-redirect-connector
  #
  # POST /waivers
  def create
    authorize :waiver_submission

    # Create a submission for this assignment in Canvas. This is required to to have the 
    # Pre-Requisites module satisfy its completion requirements in order to unlock
    # access to the rest of the Canvas modules.
    lti_score = LtiScore.new_full_credit_submission(
      current_user.canvas_user_id,
      completed_waiver_submissions_url(protocol: 'https'),
    )
    lti_advantage_api_client.create_score(lti_score)
  end

  # Shows a "thank you for submitting" page. Note that since there is no
  # local waiver's model, we use completed instead of show b/c it's a static endpoint with
  # no id.
  # GET /waivers/completed
  def completed
    authorize :waiver_submission
  end

private

  def set_base_course
    @base_course = BaseCourse.find_by_canvas_course_id!(@lti_launch.request_message.canvas_course_id)
  end

  def set_new_waivers_url
    @new_waivers_url = "https://#{Rails.application.secrets.application_host}#{new_waiver_submission_path}?state=#{@lti_launch.state}"
  end

  def waivers_already_signed?
    lti_advantage_api_client.get_result().present?
  end

  def lti_advantage_api_client
    @lti_advantage_api_client ||= LtiAdvantageAPI.new(@lti_launch)
  end
end

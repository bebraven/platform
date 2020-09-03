require 'lti_advantage_api'

class FormSubmissionsController < ApplicationController
  include LtiHelper

  # Non-standard controller without normal CRUD methods. Disable the convenience module.
  def dry_crud_enabled?
    false
  end

  # POST /form_submissions
  # POST /form_submissions.json
  def create
    ActiveRecord::Base.transaction do
      request.request_parameters.keys.each do |key|
        next if ['authenticity_token', 'commit'].includes? key
        FormKeyValue.create_with(value: request.request_parameters[key]).create_or_find_by!(key: key, user: current_user)
      end
    end
  end

  # GET /form_submissions/peer_review
  def peer_review
    all_users = []
    @lti_launch.section_ids.each do |section_id|
      all_users += CanvasAPI.client.get_section_students(@lti_launch.course_id, section_id)
    end
    @users = all_users.delete_if { |x| x['id'] == current_user.canvas_id }
  end
end

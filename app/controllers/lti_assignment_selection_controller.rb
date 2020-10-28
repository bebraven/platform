class LtiAssignmentSelectionController < ApplicationController
  include LtiHelper
  layout 'lti_placement'

  before_action :set_lti_launch, only: [:new, :create]
  skip_before_action :verify_authenticity_token, only: [:new, :create], if: :is_sessionless_lti_launch?

  # Non-standard controller without normal CRUD methods. Disable the convenience module.
  def dry_crud_enabled?() false end

  def new
    params.require([:state])
    authorize @lti_launch

    @assignments = Project.all
  end
end

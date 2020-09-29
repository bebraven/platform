
# TODO: This will be used by either an LC to take attendance for a particualte Fellow at a particular event
# OR to show the attendance status (aka grade) for a Fellow (prob don't need a UI here, just the ability to query for the status and maybe not even that)
class AttendanceStatusesController < ApplicationController
  include LtiHelper
  layout 'lti_placement'

  before_action :set_lti_launch, only: [:create, :show]
#  skip_before_action :verify_authenticity_token, only: [:create, :show], if: :is_sessionless_lti_launch?

  def new
# TODO: shows the current status for a fellow at a particular event and allows an LC (or staff) to change it.
  end

  def create
# TODO: if attendance hasn't been taken for a particular fellow + event, actually created the attendance status
  end

  def update
# TODO: if we're changing a previously entered value, this updates the attendance.
  end

end

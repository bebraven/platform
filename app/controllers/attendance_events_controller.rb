require 'canvas_api'

# TODO: This will be used to show or create attendance events (eg. LL or capstone) that a designer can
# insert as an assignment into a Fellow course and which we can show to an LC in the corresponding 
# LC Playbook in order for them to take attendance.
#
# For every Accelerator course template, we would create a list of these attendance_events mapped to that course template. 
# When a Fellow views an assignment that is attendance_event, it will just tell them that they will get credit once
# the LC (or TA or staff) takes attendance.
#
# For someone taking attendance, We need to be able to get from a particular LC in the LC playbook course to a list of these events in the 
# corresponding Accelerator course template. We'll do this through the section. Both both the LC and Fellow are in
# the same section in the Accelerator course. This is setup when they are provisioned through the account creation flow using their
# joint Cohort object in Salesforce. We'll either need to look up the Canvas section the LC is in on the fly or store the
# section ID locally and keep it in sync when changes happen. With that section, we can determine the course to look
# up attendance events when an LC is viewing the take attendance form (or a staff member or TA is doing it on their behalf).
#
# In order to avoid mapping each LC playbook where we embed an attendance form and in order to have a generic
# top-level "take attendance" page on the left nav and course home page, we'll use the index action of this
# controller as the endpoint to iframe into Rise360. The index will have a dropdown of attendance events to
# take attendance for and we'll try and choose the default one selected using the current time and looking up
# the next attendance event coming up. More details about how to do that below
#
# When using the course mgmt tools to launch a course, the attendance events in the Accelerator course template will have to be cloned
# and updated with the new course/assignment IDs. ALSO, the LC Playbook will need to be cloned at the same time and
# be able to look up events in the freshly cloned Accelerator course. The LC Playbook part doesn't matter if
# we use the section approach above along with looking up events using the timestamp. 
#
class AttendanceEventsController < ApplicationController
  include LtiHelper
  layout 'lti_placement'

  before_action :set_lti_launch, only: [:create, :show, :index]
# TODO: remove me. HAX
  skip_before_action :authenticate_user!
  skip_before_action :ensure_admin!
#  skip_before_action :verify_authenticity_token, only: [:create, :show], if: :is_sessionless_lti_launch?

  # TODO: HAX
  def dry_crud_enabled?() false end

  def index
# TODO: look up the accelerator course that this LC's cohort is mapped to using the canvas section ID. Query salesforce, Canvas, store locally?
# Show 2 things:
# 1) a dropdown where they can choose from all attendance events in the accelerator course 
# 2) default to show the single attedance event that is most likely the current one they want to take attendance for
#    by using timestamps. E.g. show the most recent event whose time has passed up to a day before the next event. 
#    A day before the next event, switch to that one if this event already has attendance taken. If the most recent
#    event doesn't have attendance taken, keep showing it until the start of the next event to switch to that one (this will encourage
#    LCs to take last weeks attendance if they didn't before they take this week's).

# Note: need to use the effective LC in case staff are trying to view their attendance on their behalf.

# TODO: think about whether we want to store the section IDs locally during sync to lms. If a staff member changes stuff
# in canvas, i assume it will get undone in the next nightly sync. If that is enforced across the board, that it all
# has to be done through salesforce, then i think we can make the sync keep the section id's up to date in our local
# database so that we can quickly look up the section and course to query for events and fellows.

# If we have to look up the course using the canvas section ID, this API endpoint would work.
   @section = CanvasAPI.client.get_section('4') # 4 is an example Canvas section ID
puts "### here is what a canvas section through their API looks like: #{@section.inspect}"

# TODO: look up the course_id to target
# For HAX, i just inserted two of these using the console with this canvas_course_id
    @attendance_events = AttendanceEvent.where(canvas_course_id: 48)

# TODO: use the current time and the due date for the associated canvas assignment for this LCs section to decide which one to default to
    @current_event = AttendanceEvent.find(2)

# TODO: look up teh fellows in this LC's section in order to populate the list of folks to take attendance for
    @fellows = User.where(id: [8,9, 10])

# TODO: prepopulate existing attendance in case someone is coming back to fix something up. 
  end

  def new
# TODO: shows a form that let's the designer create a new attednance event for a course template. The name should
# match the name of the assignment this event will be associated with. Figure out how we'll do that.
# 
# QQ: Restrict this to course templates? Or do we want the ability to customize a launched course and
# add special attendance events? Prob want to be able to add to a course and course template.
  end

  def create
# TODO: actually creates the event tied to the course_template and stores the Canvas asssignment ID and name
  end

  def show
# TODO: show a single attendance event. For the LC, populate it with a list of Fellows in their cohort. For a Fellow, show
# present, late, or absent that their LC entered or some language around the fact that the LC will take attendance if they haven't.
  end

private

  def set_lti_launch
    if params[:state]
      @lti_launch = LtiLaunch.current(params[:state])
    else
      # TODO: HAX to prove that we can get the LtiLaunch state when inside an iframe inside Rise360 content.
      raise "BadRequest TODO" unless request.referrer
      referrer = Addressable::URI.parse(request.referrer)
  puts "### referrer = #{referrer}"
  
      referrer_query_params = referrer.query_values
  puts "### referrer_query_params = #{referrer_query_params}"
  
  puts "### referrer_query_params['auth'] = #{referrer_query_params['auth']}"
      state = referrer_query_params['auth'][/LtiState (.*)$/, 1]
  
  puts "### parsed state out!!! state = #{state}" 
  
  @lti_launch = LtiLaunch.current(state)
  
  puts "### found LtiLaunch = #{@lti_launch.inspect}"
 
  # TODO: hax to get ngrok'd iframe to connect inside a Rise360 package. Figure
  # out how to make it work with CSP 
  response.headers['X-Frame-Options'] = 'ALLOWALL'
    end
  end
end

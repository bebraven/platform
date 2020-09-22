# Handles launching and submitting waivers that we require folks to sign in order to participate
# in the course.
#
# The waivers form is created in FormAssembly. Here is one example: https://braven.tfaforms.net/forms/builder/5.0.0/4810809
# We configure the a Post Redirect connector on form submission and point it at https://platform.bebraven.org/waivers
# In the Connetor, we configure the fields to be send to the above endpoint with the canvas_user_id and canvas_course_id
# that the waiver is being signed for.
#
# Note: the FormAssembly e-Signature functionality requires access to cookies/local storage. This doesn't work in Chrome
# incognito (and probably Firefox) b/c they disable third party cookies by default. To get around this, we start with a
# launch view where you click a link to bring you to the platform app instead of being inside an iFrame in Canvas.
# We serve the FormAssembly form from our domain using their Rest API: https://help.formassembly.com/help/340360-use-a-server-side-script-api
# so that everything works.
class WaiversController < ApplicationController
  layout 'lti_placement'
  include LtiHelper

# TODO: can I get rid of this? I was testing on the actual FA site, but if it's all embedded and stuff will it work?
  skip_before_action :verify_authenticity_token

  before_action :set_lti_launch, only: [:new, :create, :launch]
  before_action :set_waivers_already_signed, only: [:new, :launch]

  # This took forever to get right b/c content_security_policy is a DSL and you can't just
  # append normal items to an existing array. An alternative if we need to do this
  # sort of thing widely is https://github.com/github/secure_headers which has named overrides.
  content_security_policy do |policy|
     global_script_src =  policy.script_src
     # TODO: make this configurable with an ENV var.
     policy.script_src "https://braven.tfaforms.net:*", :unsafe_eval, :unsafe_inline, -> { global_script_src }
  end

  # Presents a page to launch the Waivers form in its own window (aka this window) instead of inside an iFrame where
  # the Waivers assignment is shown in Canvas.
  def launch
# TODO: don't hardcode.
    @new_window_url = "https://platformweb/waivers/new" 
    @new_window_url += "?state=#{@lti_launch.state}" if @lti_launch
  end

  # Show the FormAssembly waiver form for them to sign.
  def new 
    # TODO: remove me. tmp for testing:
    puts "### Display waivers to sign: WaiversController.new called with params = #{params.inspect}"

  unless @waivers_already_signed
    if params[:tfa_next]
      url = "/rest/#{params[:tfa_next]}"
    else
      # TODO: get the participant ID for the current canvas user from Salesforce. Also get the FormAssembly Form ID 
      # for this Course (aka Program in SF). Put the two together to create this link.
      # Test Waiver form
      #url = '/rest/forms/view/4810809?participantId=a2X1J0000014qozUAA' # xTestBooster3
      url = '/rest/forms/view/4810809?participantId=a2X1J000000mQfEUAU' # xTestHighlanderFellow1
    end
    # TODO: don't hardcode.
    response = RestClient.get('https://braven.tfaforms.net'+url)
    
    @form_head, @form_body = response.body.split('<!-- FORM: BODY SECTION -->') # This is weird, but it's how their REST API is meant to be used
    
    setup_head()
    setup_body()
  end

  end

  # Handle the submission of the FormAssembly waiver form. This is configured in a Post Redirect Connector in FormAssembly
  def create
    #TODO: remove me. tmp for testing
    puts "### Submit signed waivers: WaiversController.create called with params = #{params.inspect}" 

    raise ArgumentError.new, "FormAssembly Connector must be configured to send a 'canvas_user_id' parameter" unless params[:canvas_user_id]
    raise ArgumentError.new, "FormAssembly Connector must be configured to send a 'canvas_course_id' parameter" unless params[:canvas_course_id]

    # TODO: clean / DRY me up. Remove debug "puts"
    course = Course.find_by_canvas_course_id(params[:canvas_course_id])
puts "#### course for canvas course (#{params[:canvas_course_id]}) = #{course}"
    cm = CourseMembership.joins(:user).where('users.canvas_id' => params[:canvas_user_id], 'course_memberships.base_course_id' => course.id).first
puts "### updating CourseMemebership: #{cm}"
    cm.waivers_signed_at = DateTime.now
    cm.save!

  end

private

  # The Referrer-Policy is "strict-origin-when-cross-origin" by default which causes
  # the fullpath to not be sent in the Referer header when the Submit button is clicked.
  # This leads to Form Assembly not knowing where to re-direct back to for forms with multiple
  # pages (e.g. for one with an e-signature). Loosen the policy so the whole referrer is sent.
  def setup_head
    @form_head.insert(0, '<meta name="referrer" content="no-referrer-when-downgrade">')
  end

  # Insert an <input> element that will submit the state with the form so that it works in
  # browsers that don't have access to session and need to authenticate using that.
  #
  # Note: I tried setting this up on the FormAssembly side of things, but you can't control the
  # names of the fields that you can pre-populate things when loading the form. They are things like
  # "tfa_26" depending on how many and what order you add fields. See:
  # https://help.formassembly.com/help/prefill-through-the-url
  def setup_body
    if @lti_launch
      doc = Nokogiri::HTML::DocumentFragment.parse(@form_body)
      form_node = doc.at_css('form')
      form_node.add_child('<input type="hidden" value="' + @lti_launch.state + '" name="state" id="state">')
      @form_body = doc.to_html
    end
  end

  def set_waivers_already_signed
    if @lti_launch
      canvas_course_id = @lti_launch.request_message.canvas_course_id
      canvas_user_id = @lti_launch.request_message.canvas_user_id
      course = Course.find_by_canvas_course_id(canvas_course_id)
      cms = CourseMembership.joins(:user).where('users.canvas_id' => canvas_user_id, 'course_memberships.base_course_id' => course.id)
      @waivers_already_signed = cms.first.waivers_signed_at.present? if cms
    end
  end
end

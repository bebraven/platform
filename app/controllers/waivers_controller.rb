# frozen_string_literal: true

require 'lti_advantage_api'
require 'canvas_api'

# Handles publishing and unpublishing Waivers forms that Fellows need to sign
# in order to participate in the course.
#
# The waivers forms are created in FormAssembly. Here is one example: https://braven.tfaforms.net/forms/builder/5.0.0/4810809
# We configure the a Post Redirect connector on form submission and point it at https://platform.bebraven.org/waiver_submissions
# In the Connetor.
#
# Note: the FormAssembly e-Signature functionality requires access to cookies/local storage.
# This doesn't work in Chrome incognito (and probably Firefox) b/c they disable third party cookies
# by default. To get around this, we start with a launch view where you click a link to bring you
# to the platform app instead of being inside an iFrame in Canvas. We serve the FormAssembly 
# form from our domain using their Rest API: https://help.formassembly.com/help/340360-use-a-server-side-script-api
# so that everything works.
#
# After publishing the waivers. The actual launch and submission are handled by WaiverSubmissionsController
class WaiversController < ApplicationController
  include DryCrud::Controllers::Nestable

  # Adds the #publish and #unpublish actions
  include Publishable

  layout 'admin'

  nested_resource_of BaseCourse

  # Note: this is the actual name of the assignment. The convention
  # for assignment naming is things like: CLASS: Learning Lab2,
  # MODULE: Lead Authentically, TODO: Complete Waivers
  WAIVERS_ASSIGNMENT_NAME = 'TODO: Complete Waivers'

  def base_course
    @base_course
  end

  def assignment_name
    WAIVERS_ASSIGNMENT_NAME
  end

  def lti_launch_url
    launch_waiver_submissions_url(protocol: 'https')
  end

end

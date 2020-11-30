# frozen_string_literal: true

# A base controller for all FormAssembly controllers to inherit from.
# Provides common utilities and CSS styles.
#
# When inheriting this, you must add the following methods on the controller
# in order to use the methods it provides:
#
# Usage:
# class MyController < FormAssemblyController
#  attr_reader :base_course, :lti_launch
# end
class FormAssemblyController < ApplicationController
  include LtiHelper

  layout 'lti_canvas'

  skip_before_action :verify_authenticity_token, only: [:create], if: :is_sessionless_lti_launch?

  # The FormAssembly Javascript does an eval() so we need to loosen the CSP.
  # 
  # This syntax took forever to get right b/c content_security_policy is a DSL and you can't just
  # append normal items to an existing array. An alternative if we need to do this
  # sort of thing widely is https://github.com/github/secure_headers which has named overrides.
  content_security_policy do |policy|
     global_script_src =  policy.script_src
     policy.script_src "#{Rails.application.secrets.form_assembly_url}:*", :unsafe_eval, -> { global_script_src }
  end

protected

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
  #
  # TODO: if you try to go Back in the browser after submitting the final e-signature review
  # form, the call to the FormAssembly API with that tfa_next param returns an empty body and this 
  # throws an exception. Do something more graceful: https://app.asana.com/0/1174274412967132/1199231117515065
  def setup_body
    doc = Nokogiri::HTML::DocumentFragment.parse(@form_body)
    form_node = doc.at_css('form')
    form_node.add_child('<input type="hidden" value="' + html_safe_state + '" name="state" id="state">')
    @form_body = doc.to_html
  end

  # This needs to be safe to inject in HTML and not expose an XSS vulnerability.
  # Reading it from the @lti_launch is safe since we generate that, but reading it
  # from a query param is not safe.
  def html_safe_state
    @lti_launch.state
  end

  def form_assembly_info
    @form_assembly_info ||= FetchSalesforceFormAssemblyInfo.new(base_course.canvas_course_id, current_user).run
  end
end

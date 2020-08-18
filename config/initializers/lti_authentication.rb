# frozen_string_literal: true
require 'lti_launch'

module LtiAuthentication

  # Note: if you change this, keep it in sync with: app/javascript/packs/xapi_assignment.js
  LTI_AUTH_HEADER_PREFIX='LtiState'

  class WardenStrategy < Warden::Strategies::Base
    
    # True if this strategy should be run for this request
    def valid?
      @lti_state = fetch_state
      @lti_state.present?
    end

    def authenticate!
      Honeycomb.start_span(name: 'LtiAuthentication.authenticate!') do |span|
        span.add_field('lti_auth.state', @lti_state)
        user = nil
        url = nil
        status = nil
        message = nil
        canvas_id = nil

        # TODO: cache this for an hour. Or a day? It's hit alot.
        # https://app.asana.com/0/1174274412967132/1188248367583275
        unless ll = LtiLaunch.is_valid?(@lti_state)
          status = :forbidden
          message = "LtiAuthentication::WardenStrategy couldn't find LtiLaunch with state = '#{@lti_state}'"
          return finish_authenticate(span, status, message) 
        end

        url = ll.target_link_uri
        canvas_id = ll.request_message.canvas_user_id
        unless user = ll.user
          status = :forbidden
          message = "LtiAuthentication::WardenStrategy couldn't find user with canvas_id = #{canvas_id}"
          return finish_authenticate(span, status, message, url, canvas_id)
        end

        status = :ok
        message = "Authenticated user_id = #{user.id} using LtiAuthentication::WardenStrategy"
        return finish_authenticate(span, status, message, url, canvas_id, user)
      end
    end

private

    def finish_authenticate(span, status, message, url = nil, canvas_id = nil, user = nil)
      span.add_field('lti_auth.status', status)
      span.add_field('lti_auth.message', message)
      span.add_field('lti_auth.url', url) if url 
      span.add_field('lti_auth.canvas_id', canvas_id) if canvas_id
      if status == :ok
        Rails.logger.debug(message)
        success!(user)
      else
        Rails.logger.warn(message)
        handle_failure(status)
      end
    end

    # There are 3 possible locations where the lti state may be stored in a request:
    # params[:state] is there for routes hit using LtiLaunchController
    # params[:auth] is there when Rise360 packages load index.html. We piggyback off the "auth" query param that Rise 
    #               packages can be configured with and store it there when launching them.
    # request.headers[:authorization] is there for Ajax requests from both Rise360 and Project's that send xAPI statements.
    #                                 This is the result of configurign Tincan.js with the "auth" option.
    def fetch_state
     lti_state = params[:state] || params[:auth]
     unless lti_state
       lti_state = request.headers[:authorization][/#{LTI_AUTH_HEADER_PREFIX} (.*)$/, 1] if request.headers[:authorization]
     end
     lti_state
    end

    def handle_failure(response)
      custom!(response)
    end

  end
end


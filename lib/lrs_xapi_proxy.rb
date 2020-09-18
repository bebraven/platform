# frozen_string_literal: true

# Proxies requests made to the same path as the ENV['LRS_URL'] but on this server
# to the LRS server by adding the required authentication header.
#
# This allows us to hide the authentication token from the client.
class LrsXapiProxy

  XAPI_VERSION = '1.0.2'
  XAPI_STATE_API_ENDPOINT = 'activities/state'
  XAPI_STATEMENTS_API_ENDPOINT = 'statements'
  JSON_MIME_TYPE = 'application/json'
  OCTET_STREAM_MIME_TYPE = 'application/octet-stream'

  @lrs_path = nil

  def self.lrs_path
    @lrs_path ||= URI(Rails.application.secrets.lrs_url).path
  end

  def self.request(request, endpoint, user)
    Honeycomb.start_span(name: 'LrsXapiProxy.request') do |span|
      span.add_field('path', "#{lrs_path}/#{endpoint}")
      span.add_field('user.id', user.id)
      span.add_field('user.email', user.email)
      span.add_field('method', request.method)

      return unless request.method == 'GET' || request.method == 'PUT'

      # Rise360 sends and receives payloads to the /activities/state xAPI endpoint that are things like
      # like the following, both JSON and just plain content, but for both it expects the Content-Type to
      # be 'application/octet-stream' (or perhaps something equivalent, but this is what the browser shows).
      #   stateId=cumulative_time:    123456 or NaN
      #   stateId=bookmark:           #/lessons/xQvXXBKjohmGHnPUlyck9VqMlQ0hgcgy
      #   stateId=suspend_data:       {"v":1,"d":[123,34]]}
      content_type = (endpoint == XAPI_STATE_API_ENDPOINT ? OCTET_STREAM_MIME_TYPE : JSON_MIME_TYPE )

      # Rewrite query string
      #
      # Note: the user_override param is used by the controller to decide the
      # the effective user to query the LRS on behalf of. It's not meant to be passed through
      # in the xAPI request.
      params = request.query_parameters.except(:user_override_id)
      params['agent'] = build_agent_hash(user).to_json if params['agent']

      # Rewrite body.
      data = nil
      if request.method == 'PUT'
        data = request.raw_post
        if content_type == JSON_MIME_TYPE
          data = JSON.parse(request.raw_post)
          data['actor'] = build_agent_hash(user) if data['actor']

          # LRS rejects NaN values for duration. This is an issue with Rise's xAPI activities with 
          # timing associated with them, e.g. "progressed".
          data['result']['duration'] = 'PT0.0S' if data.dig('result', 'duration') == 'PTNaNS'

          data = data.to_json
        end
      end

      # Inspect statements for grading purposes.
      if data.is_a? String and endpoint == XAPI_STATEMENTS_API_ENDPOINT
        save_interaction!(data, request.authorization, user)
      end

      # Forward request and return response.
      begin
        response = RestClient::Request.execute(
          method: request.method,
          url: "#{Rails.application.secrets.lrs_url}/#{endpoint}",
          payload: request.method == 'PUT' ? data : {},
          headers: {
            authorization: authentication_header,
            # Note: this version of Tincan.js uses 1.0.2. However Rise360 sends 1.0.1. This means we're
            # fibbing and telling the LRS it's 1.0.2 when it may be a different version. There doesn't seem
            # to be much of a difference though so if we run into an issue with version mismatches, we'll deal then.
            x_experience_api_version: XAPI_VERSION,
            params: params,
            content_type: (content_type if request.method == 'PUT' ),
          }.compact
        )

        # Note: I tried to just pass the content_type returned from the LRS right on through but couldn't get it to work
        # so we're just using the content_type associated with the particular path / route that we're dealing with
        response.headers[:content_type] = content_type
        response
      rescue RestClient::NotFound => e # We expect Not Found at times and just want to return that. E.g. first launch of Rise360 lesson with no stateId
        e.response
      end
    end
  end

private

  private_class_method def self.build_agent_hash(user)
    {
      objectType: 'Agent',
      name: user.full_name,
      mbox: "mailto:#{user.email}",
    }
  end

  private_class_method def self.authentication_header
    @@auth_header ||= "Basic #{Rails.application.secrets.lrs_auth_token}"
  end

  private_class_method def self.save_interaction!(data, authorization, user)
    return unless authorization&.start_with? LtiAuthentication::LTI_AUTH_HEADER_PREFIX

    # Get verb and activity_id from the payload.
    payload = JSON.parse(data)
    verb = payload.dig('verb', 'id')
    activity_id = payload.dig('object', 'id')

    # Exit early if it's not a supported verb.
    return unless (
      verb == LessonInteraction::PROGRESSED or
      verb == LessonInteraction::ANSWERED
    )

    # Get course and assignment IDs from the auth header.
    # Header looks like "<prefix> <state>".
    state = authorization.split(LtiAuthentication::LTI_AUTH_HEADER_PREFIX).last.strip
    ll = LtiLaunch.current(state)
    parsed = ll.activity_id.match /\/courses\/(?<course>\d+)\/assignments\/(?<assignment>\d+)/

    # Save to the db, raise an exception if any part of this fails.
    # We want this to 500 out if there's anything unexpected.
    case verb
    when LessonInteraction::PROGRESSED
      LessonInteraction.create!(
        verb: verb,
        user: user,
        canvas_course_id: parsed[:course],
        canvas_assignment_id: parsed[:assignment],
        activity_id: activity_id,
        progress: payload.dig('result', 'extensions',
            'http://w3id.org/xapi/cmi5/result/extensions/progress')
        )
    when LessonInteraction::ANSWERED
      LessonInteraction.create!(
        verb: verb,
        user: user,
        canvas_course_id: parsed[:course],
        canvas_assignment_id: parsed[:assignment],
        activity_id: activity_id,
        success: payload.dig('result', 'success')
      )
    end
  end
end

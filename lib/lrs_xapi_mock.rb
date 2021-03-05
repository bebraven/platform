# frozen_string_literal: true

# Mocks responses to LRS/xAPI requests.
#
# This allows us to support Rise 360 content, without actually having an LRS.
# Rise360 sends and receives payloads to the /activities/state xAPI endpoint that are things like
# like the following, both JSON and just plain content, but for both it expects the Content-Type to
# be 'application/octet-stream' (or perhaps something equivalent, but this is what the browser shows).
#   stateId=cumulative_time:    123456 or NaN
#   stateId=bookmark:           #/lessons/xQvXXBKjohmGHnPUlyck9VqMlQ0hgcgy
#   stateId=suspend_data:       {"v":1,"d":[123,34]]}
class LrsXapiMock

  XAPI_STATE_API_ENDPOINT = 'activities/state'
  XAPI_STATEMENTS_API_ENDPOINT = 'statements'
  OCTET_STREAM_MIME_TYPE = 'application/octet-stream'
  SUSPEND_DATA_STATE_ID = 'suspend_data'
  CUMULATIVE_TIME_STATE_ID = 'cumulative_time'
  BOOKMARK_STATE_ID = 'bookmark'
  # Note: bookmark max length is an arbitrary "small" number so that people can't
  # shove large files in here and use us as a file host. More details on expected
  # bookmark values below.
  BOOKMARK_MAX_LENGTH = 256
  LRS_PATH = '/data/xAPI'

  class LrsXapiMockError < StandardError; end

  # Returns a hash with keys {:code, :body}, OR nil.
  def self.handle_request!(request, endpoint, user)
    Honeycomb.start_span(name: 'LrsXapiMock.handle_request!') do |span|
      span.add_field('path', "/#{endpoint}")
      span.add_field('user.id', user.id)
      span.add_field('user.email', user.email)
      span.add_field('method', request.method)

      return unless request.method == 'GET' || request.method == 'PUT'

      # Handle PUT for both endpoints.
      if request.method == 'PUT'
        data = request.raw_post

        case endpoint
        when XAPI_STATEMENTS_API_ENDPOINT
          # Save relevant info from statements, for grading purposes.
          save_interaction!(data, request.authorization, user)
          return {
            code: 204,  # No Content
            body: nil,
          }
        when XAPI_STATE_API_ENDPOINT
          state_id = request.params['stateId']
          activity_id = request.params['activityId']

          # Save the state.
          save_state!(activity_id, state_id, data, request.authorization, user)
          return {
            code: 204,  # No Content
            body: nil,
          }
        else
          return {
            code: 404,  # Not Found
            body: 'Not Found',
          }
        end
      end

      # Handle GET only for the state endpoint.
      if request.method == 'GET' and endpoint == XAPI_STATE_API_ENDPOINT
        state_id = request.params['stateId']
        activity_id = request.params['activityId']

        # Return the state.
        state = get_state(activity_id, state_id, request.authorization, user)
        if state
          return {
            code: 200,  # OK
            body: state.value,
          }
        else
          return {
            code: 404,  # Not Found
            body: 'Not Found',
          }
        end
      end
    end
  end

private

  private_class_method def self.parse_activity_id(authorization)
    # Get course and assignment IDs from the LtiLaunch specified in the auth header.
    # Header looks like "<prefix> <state>".
    state = authorization.split(LtiConstants::AUTH_HEADER_PREFIX).last.strip
    ll = LtiLaunch.current(state)
    # Parse the canvas course and assignment IDs out of the LTI launch's activity ID.
    # See app/model/lti_launch.rb for more on activity ID; note this is entirely unrelated
    # to the LRS activity ID.
    ll.activity_id.match /\/courses\/(?<course>\d+)\/assignments\/(?<assignment>\d+)/
  end

  private_class_method def self.save_state!(activity_id, state_id, data, authorization, user)
    return unless authorization&.start_with? LtiConstants::AUTH_HEADER_PREFIX

    # Since this returns data as application/octet-stream, a dangerous mimetype, let's
    # do some extra validation to make it less likely someone can use this as an
    # arbitrary file host for nefarious purposes.
    # The following are known Rise360 state IDs and their expected types.
    # Raise an exception if any of them fail validation.
    case state_id
    when SUSPEND_DATA_STATE_ID
      # E.g.: {v: 1, d: [123, 34, 112, 114, ...]}
      JSON.parse(data)
    when CUMULATIVE_TIME_STATE_ID
      # E.g.: 37561
      Integer(data)
    when BOOKMARK_STATE_ID
      # E.g.: #/lessons/xQvXXBKjohmGHnPUlyck9VqMlQ0hgcgy
      raise LrsXapiMockError.new("bookmark max length exceeded") unless data.length < BOOKMARK_MAX_LENGTH
    else
      raise LrsXapiMockError.new("unknown stateId")
    end

    # Get course and assignment IDs from the LTI launch.
    parsed = parse_activity_id(authorization)

    attributes = {
      canvas_course_id: parsed[:course],
      canvas_assignment_id: parsed[:assignment],
      activity_id: activity_id,
      user: user,
      state_id: state_id,
    }

    module_state = Rise360ModuleState.find_by(attributes)
    if module_state
      module_state.update!(value: data)
    else
      attributes[:value] = data
      Rise360ModuleState.create!(attributes)
    end
  end

  private_class_method def self.get_state(activity_id, state_id, authorization, user)
    # Get course and assignment IDs from the auth header.
    parsed = parse_activity_id(authorization)

    Rise360ModuleState.find_by(
      canvas_course_id: parsed[:course],
      canvas_assignment_id: parsed[:assignment],
      activity_id: activity_id,
      user: user,
      state_id: state_id,
    )
  end

  private_class_method def self.save_interaction!(data, authorization, user)
    raise LrsXapiMockError.new("no auth header") unless authorization&.start_with? LtiConstants::AUTH_HEADER_PREFIX

    # Get verb and activity_id from the payload.
    payload = JSON.parse(data)
    verb = payload.dig('verb', 'id')
    activity_id = payload.dig('object', 'id')

    # Exit early if it's not a supported verb.
    return unless (
      verb == Rise360ModuleInteraction::PROGRESSED or
      verb == Rise360ModuleInteraction::ANSWERED
    )

    # Get course and assignment IDs from the LTI launch.
    parsed = parse_activity_id(authorization)

    # Save to the db, raise an exception if any part of this fails.
    # We want this to 500 out if there's anything unexpected.
    case verb
    when Rise360ModuleInteraction::PROGRESSED
      progress = payload.dig('result', 'extensions',
        'http://w3id.org/xapi/cmi5/result/extensions/progress'
      )
      rmi = Rise360ModuleInteraction.create!(
        verb: verb,
        user: user,
        canvas_course_id: parsed[:course],
        canvas_assignment_id: parsed[:assignment],
        activity_id: activity_id,
        progress: progress,
      )
      # Grade it now if they complete the module instead of waiting for the nightly task
      # so that they immediately see they get credit and feel good about that.
      if progress == 100
        GradeModuleForUserJob.perform_later(user, rmi.canvas_course_id, rmi.canvas_assignment_id)
      end
    when Rise360ModuleInteraction::ANSWERED
      Rise360ModuleInteraction.create!(
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

# frozen_string_literal: true

# Proxies requests made to the same path as the ENV['LRS_URL'] but on this server
# to the LRS server by adding the required authentication header.
#
# This allows us to hide the authentication token from the client.
class LrsXapiProxy

  XAPI_VERSION = '1.0.2'

  @lrs_path = nil

  def self.lrs_path
    @lrs_path ||= URI(Rails.application.secrets.lrs_url).path
  end

  def self.request(request, path, user)
    Honeycomb.start_span(name: 'LrsXapiProxy.request') do |span|
      span.add_field('path', path)
      span.add_field('user.id', user.id)
      span.add_field('user.email', user.email)
      span.add_field('method', request.method)

      return unless request.method == 'GET' || request.method == 'PUT'

      # Rewrite query string
      #
      # Note: the user_override param is used by the controller to decide the
      # the effective user to query the LRS on behalf of. It's not meant to be passed through
      # in the xAPI request.
      params = request.query_parameters.except(:user_override)
      if params['agent']
        params['agent'] = {
            name: user.full_name,
            mbox: "mailto:#{user.email}",
            objectType: 'Agent',
          }.to_json
      end

      # Rewrite body.
      # request_parameters is supposed to be formed from the POST body, but for some reason we're
      # getting duplicate params here. Every param is passed through as expected at the root level,
      # but then there's an additional key, 'lrs_xapi_proxy', that contains an exact copy of all
      # those params. Since I have no idea why this happens, and the LRS complains if you pass in
      # params it doesn't recognize, we're just passing in the contents of the duplicate key here.
      # If anyone ever figures out what's going on here and how to get rid of that extra key, this
      # should be updated to pass in just request_parameters.
      data = request.request_parameters
      if request.request_parameters['lrs_xapi_proxy'] 
        data = request.request_parameters['lrs_xapi_proxy']
      end

      if data['actor']
        data['actor'] = {
          name: user.full_name,
          mbox: "mailto:#{user.email}",
        }
      end

      # TODO: https://app.asana.com/0/1174274412967132/1185956506654833
      # LRS rejects NaN values for duration. This is an issue with Rise's xAPI activities with 
      # timing associated with them, e.g. "progressed".
      if data['result']
        if data['result']['duration'] == "PTNaNS"
          data['result']['duration'] = "PT0.0S"
        end
      end

      begin
        response = RestClient::Request.execute(
          method: request.method,
          url: "#{Rails.application.secrets.lrs_url}/#{path}",
          payload: request.method == 'PUT' ? data.to_json : {},
          headers: {
            authorization: authentication_header,
            # Note: this version of Tincan.js uses 1.0.2. However Rise360 sends 1.0.1. This means we're
            # fibbing and telling the LRS it's 1.0.2 when it may be a different version. There doesn't seem
            # to be much of a difference though so if we run into an issue with version mismatches, we'll deal then.
            x_experience_api_version: XAPI_VERSION,
            params: params,
            content_type: ('application/json' if request.method == 'PUT' ),
          }.compact
        )
        response
      rescue RestClient::NotFound => e
        e.response
      rescue RestClient::Exception => e
        span.add_field('error', e.message)
        span.add_field('http_code', e.http_code)
        span.add_field('http_body', e.http_body)
        raise
      end
    end
  end

  private_class_method def self.authentication_header
    @@auth_header ||= "Basic #{Rails.application.secrets.lrs_auth_token}"
  end
end

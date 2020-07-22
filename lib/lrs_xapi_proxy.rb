# frozen_string_literal: true

# Proxies requests made to the same path as the ENV['LRS_URL'] but on this server
# to the LRS server by adding the required authentication header.
#
# This allows us to hide the authentication token from the client.
class LrsXapiProxy

  XAPI_VERSION = '1.0.2'

  def self.lrs_path
    @@lrs_path ||= get_lrs_path
  end

  def self.request(request, path, user)
    Honeycomb.start_span(name: 'LrsXapiProxy.request') do |span|
      span.add_field('path', path)
      span.add_field('user.id', user.id)
      span.add_field('user.email', user.email)
      span.add_field('method', request.method)

      if request.method == 'GET'
        begin
          response = RestClient.get("#{Rails.application.secrets.lrs_url}/#{path}", {
            authorization: LrsXapiProxy.authentication_header,
            x_experience_api_version: XAPI_VERSION,
            params: request.query_parameters
          })
          response
        rescue RestClient::NotFound => e
          e.response
        rescue RestClient::Exception => e
          span.add_field('error', e.message)
          span.add_field('http_code', e.http_code)
          span.add_field('http_body', e.http_body)
          raise
        end
      elsif request.method == 'PUT'
        # Rewrite body.
        # request_parameters is supposed to be formed from the POST body, but for some reason we're
        # getting duplicate params here. Every param is passed through as expected at the root level,
        # but then there's an additional key, 'lrs_xapi_proxy', that contains an exact copy of all
        # those params. Since I have no idea why this happens, and the LRS complains if you pass in
        # params it doesn't recognize, we're just passing in the contents of the duplicate key here.
        # If anyone ever figures out what's going on here and how to get rid of that extra key, this
        # should be updated to pass in just request_parameters.
        data = request.request_parameters['lrs_xapi_proxy']
        if data['actor']
          data['actor'] = {
            name: user.full_name,
            mbox: "mailto:#{user.email}"
          }
        end
        body = data.to_json

        begin
          response = RestClient.put("#{Rails.application.secrets.lrs_url}/#{path}", body, {
            authorization: LrsXapiProxy.authentication_header,
            x_experience_api_version: XAPI_VERSION,
            params: request.query_parameters,
            content_type: 'application/json'
          })

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
  end

private

  def target_uri_for(fullpath)
    URI("#{LrsXapiProxy.lrs_base_uri}#{fullpath}")
  end

  def self.lrs_base_uri
    @@lrs_base_uri ||= get_lrs_base_uri
  end

  def self.authentication_header
    @@auth_header ||= "Basic #{Rails.application.secrets.lrs_auth_token}"
  end

  def self.path_to_proxy_regex
    @@ptpr ||= /^#{Regexp.escape(lrs_path)}/
  end

  def self.get_lrs_path
    lrs_url = URI(Rails.application.secrets.lrs_url)
    lrs_url.path
  end

  def self.get_lrs_base_uri
    url = URI(Rails.application.secrets.lrs_url)
    "#{url.scheme}://#{url.host}"
  end

end

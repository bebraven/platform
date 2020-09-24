# frozen_string_literal: true
require 'rack/proxy'

# Implements a reverse proxy to our published LessonContent on AWS S3.
# Needed to avoid security concerns with cross origin / AJAX / XHR browser issues.
# More context: https://app.asana.com/0/1174274412967132/1186566037117865
#
# Hitting a path like:
#
#   https://platformweb/lesson_contents_proxy/the/path/on/aws/s3
# 
# will cause the request/response to be proxied to the configured AWS S3 bucket at
#
#   https://bucket.s3.amazonaws.com/the/path/on/aws/s3
#
class LtiRise360Proxy < Rack::Proxy

  PROXIED_PATH='/rise360_proxy'
  PROXY_REGEX=/^#{Regexp.escape(PROXIED_PATH)}(\/.*)$/

  # E.g. https://platformweb/lesson_contents_proxy
  def self.proxy_url
    # This is hard-coded to HTTPS b/c none of this stuff works over HTTP and in dev thats the default
    # if we use a helper URL like: Rails.application.routes.url_helpers.root_url
    @proxy_url ||= "https://#{Rails.application.secrets.application_host}#{PROXIED_PATH}"
  end

  def perform_request(env)
    request = Rack::Request.new(env)
    if request.path =~ PROXY_REGEX
      env["HTTP_HOST"] = @backend.host # e.g. some-bucket.s3.amazonaws.com
      env['PATH_INFO'] = $1            # The match in the regex above
      super(env)
    else
      @app.call(env)
    end
  end

end

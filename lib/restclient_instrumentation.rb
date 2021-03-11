# frozen_string_literal: true

# Prepend this module to RestClient::Request in order to instrument
# calls to `execute` with Honeycomb tracing and error logging.
#
# Note: all calls through RestClient boil down to executing this instance method.
module RestClientInstrumentation
  def execute &block
    ret_val = nil

    # Go up the stack looking for the first file not in the restclient gem 
    # (starting at caller of this, aka the 2nd index, and searching a max of 5 levels) 
    calling_file_path = caller_locations(2,5).find {|cl| cl.path.exclude?('restclient')}.path
    calling_class = File.basename(calling_file_path, '.rb').camelize

    # I'm trying to mimic what normal Rails request's send:
    # https://guides.rubyonrails.org/active_support_instrumentation.html#process-action-action-controller
    Honeycomb.start_span(name: "RestClient.#{method}") do |span|
      span.add_field('class_name', calling_class)
      span.add_field('method', method)
      span.add_field('url', redacted_url) # Strips out password if it's in there.
      span.add_field('timestamp', DateTime.now)

      # TODO: move this to FilterLogging. Also, make sure and filter out the session ID header
      redacted_headers = processed_headers.dup
      redacted_headers['Authorization'] = '[REDACTED]' if redacted_headers['Authorization']
      span.add_field('headers', redacted_headers)
      begin
        ret_val = super(&block)
        span.add_field('status', ret_val.code)
      rescue RestClient::Exception => e
        Rails.logger.error("{\"Error\":\"#{e.message}\"}")
        error_response = e.http_body
        Rails.logger.error(error_response)
        span.add_field('error', e.message)
        span.add_field('status', e.http_code)
        # Note: can't use error_detail field name. It's overwritten somewhere with the exception 
        # message detail, not the actual response.
        span.add_field('error_response', error_response) 

        if e.is_a?(RestClient::BadRequest) and error_response =~ /JWS signature invalid/
          Rails.logger.error('TROUBLESHOOTING HINT: Copy/pasta the "Public JWK URL" from the Developer Key ' \
                             'in Canvas into the browser and make sure it returns a valid list of keys.')
        end

        raise
      end
    end

    ret_val
  end
end

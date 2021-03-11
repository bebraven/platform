# frozen_string_literal: true

require 'filter_logging'

# Endpoint to handle Honeycomb instrumentation sent from Javascript
#
# Inspriation taken from these repos and the Honeycomb beeline source:
#  - https://github.com/carwow/honeykiq
#  - https://github.com/thewoolleyman/honeycomb-react-rails-fullstack-tracing
#
# Note: we have some Honeycomb wrapper classes in honeycomb.js to help with sending
# Boomerang events from Javasript to this controller. They are mostly meant for helping 
# to make sure the instrumentation you add ends up in a Boomerang beacon that makes 
# sense as a "span". HOWEVER, this controller is the one mostly responsible for translating built-in
# Boomerang field names / values into normalized field names / values that match the rest of
# the Rails Honeycomb Beeline instrumentation to allow us to easily query for and analyze the data.
class HoneycombJsController < ApplicationController
  skip_before_action :verify_authenticity_token
  wrap_parameters false # Disable putting everything inside a "honycomb_j" param. This controller doesn't represent a model.

  # Slightly undocumented header to use to propagate traces in a distributed fashion.
  # I noticed this mentioned in the docs about Faraday doing this: https://docs.honeycomb.io/getting-data-in/ruby/beeline/#faraday
  # and dug into the code to do the same. One example here: 
  #   https://github.com/honeycombio/beeline-ruby/blob/6db9d6e0f696d93212100cca5efdeefc7723afb7/lib/honeycomb/integrations/faraday.rb#L25
  # This is where Beeline uses it to setup the trace and spans in the current context:
  #   https://github.com/honeycombio/beeline-ruby/blob/6db9d6e0f696d93212100cca5efdeefc7723afb7/lib/honeycomb/integrations/rack.rb#L35
  X_HONEYCOMB_TRACE_HEADER = 'X-Honeycomb-Trace'

  # Takes a span from Javascript and sends it to Honeycomb. The trace for the controller that
  # that rendered the page must be serialized in the 'X-Honeycomb-Trace' header so that we can
  # add this span as a child of that trace.
  #
  # Note: Honeycomb Beeline looks for this header and uses it to setup the traces and spans that are
  # auto-instrumented. If you try and directly setup the trace_id and parent_id without using this header,
  # the spans in this trace won't be in the same trace as the serialized one.
  #
  # Note: we made an active decision not to whitelist incoming params and just let everything through.
  # You have to be logged in (or have a valid state param for the session) to hit this controller,
  # so only registered users will be able to hit this. If one of our users decides to send random
  # stuff from the browser console or a script, we're logging their user info so we can chat with them and worst case
  # is we have to ask Honeycomb to purge a bunch of fields that we don't want (or just let them go stale)
  def send_span
    authorize :honeycomb_js

    existing_trace_to_add_to = request.headers[X_HONEYCOMB_TRACE_HEADER]
    raise ActionController::BadRequest, "Missing '#{X_HONEYCOMB_TRACE_HEADER}' header" unless existing_trace_to_add_to 

    span_name = params[:name] || 'javascript.event'
    duration = params['t_done']

    if is_page_load_beacon?
      span_name = 'javascript.page.load'
    elsif is_page_unload_beacon?
      span_name = 'javascript.page.unload'
      duration = 0 # the duration passed is actually for the page.load, so 0 it out.
    end

    PropagatedSpan.new(span_name, existing_trace_to_add_to, duration).send_to_honeycomb() do |span|

      # Add some standard common server side accessible fields to make it easier to query for and analyze when troubleshooting.
      span.add_field('user.id', current_user.id)
      span.add_field('user.canvas_user_id', current_user.canvas_user_id)
      span.add_field('user.email', current_user.email)
      span.add_field('user.first_name', current_user.first_name)
      span.add_field('user.last_name', current_user.last_name)

      translate_boomerang_fields(span)

      # Add the Boomerang sent data
      params.each { |key, value| span.add_field(key, value) }
    end

    head :no_content
  end

  # Standardize some Boomerang fields to Rails equivalents for easier querying.
  def translate_boomerang_fields(span)
      if params[:u] # "u" stands for "url" 
        pathinfo = URI(params[:u])
        span.add_field('request.path', pathinfo.path)
        span.add_field('request.query_string', pathinfo.query)
      end

      if params['http.initiator'] == 'xhr'
        method = params['http.method'] || 'GET' # Annoyingly, 'http.method' may not be set for GET. If missing on XHR beacon, it's GET.
        span.add_field('request.method', method)
        status = params['http.errno'] || '200'
        span.add_field('response.status_code', status)
      end

      span.add_field('javascript.timestamp', beacon_timestamp) if params['rt.end']
  end

  def is_page_load_beacon?
    !is_page_unload_beacon? && !params.key?('http.initiator') && !params.key?('early') 
  end

  def is_page_unload_beacon?
    params.key?('rt.quit')
  end

  # The time that the event completed on the client side (as reported based on the client's clock).
  # Boomerang sends the number of seconds and milliseconds since the Epoch. Divide by 1000
  # to get seconds with fractional milliseconds like Time expects.
  #
  # Note: don't use the client side timestamp as the actual timestamp of the event
  # b/c the user's clock may be skewed by minutes, hours, or even days. The Honeycomb
  # JS instrumentation docs mention that is their experience. Putting this here so we can
  # get a sense of how much impact the network and rails server processing time is impacting
  # any gaps that show up in our traces. The JS span duration's should be accurate, but the
  # timestamp will be when the server received the event and not when the client says the event
  # happened.
  #
  # The time format used is the same in libhoney: 
  # https://github.com/honeycombio/libhoney-rb/blob/3607446da676a59aad47ff72c3e8d749f885f0e9/lib/libhoney/transmission.rb#L187
  def beacon_timestamp
    Time.at(params['rt.end'].to_f / 1000.0).iso8601(3)
  end

  # Represents a Honeycomb::Span propagated from elsewhere using the X-Honeycomb-Trace header.
  #
  # Note: we use the current_span as the parent span instead of the original one so that we can
  # see all the layers in the trace just in case something bad happens with this controller
  # and we need to troubleshoot and tie it all together. 
  # (e.g. if this controller get's bombarded with requests and the server can't keep up)
  class PropagatedSpan

    def initialize(name, serialized_trace, duration_ms)
      @name = name
      @duration_ms = duration_ms
      @trace_id, @parent_span_id = TraceParser.parse(serialized_trace)
      unless @trace_id and @parent_span_id
        raise ActionController::BadRequest, "Cannot parse serialized_trace: #{serialized_trace} into " \
                                            "[@trace_id: #{@trace_id}, @parent_trace_id: #{@parent_span_id}]"
      end
    end

    # Sends this span to Honeycomb's servers.
    #
    # Takes a block that is called with the span (aka event) so the caller can use
    # span.add_field() just like the Honeycomb.start_span(...) { |span| span.add_field(...) }
    # semantics
    def send_to_honeycomb()
      Honeycomb.libhoney.event.tap do |event|
        yield event # Do this first so we overwrite any of these fields if they happen to be sent in the beacon.
        event.add_field('name', @name)
        event.add_field('trace.trace_id', @trace_id)
        event.add_field('trace.parent_id', Honeycomb.current_span.id)
        event.add_field('duration_ms', @duration_ms)
      ensure
        Rails.logger.debug("  Sending JS span '#{@name}' to Honeycomb: trace.trace_id=#{@trace_id}")
        if (event.writekey)
          # We have to explicitly run the logic in the Honeycomb.config.presend_hook here
          # b/c apparently using the lower layer "libhoney" object doesn't run the hook.
          FilterLogging.filter_honeycomb_data(event.data) if FilterLogging.is_enabled?
          event.send
        else
          Rails.logger.debug("  Skipped sending. Honeycomb isn't configured.")
        end
      end
    end

    class TraceParser
      extend Honeycomb::PropagationParser
    end
  end

end

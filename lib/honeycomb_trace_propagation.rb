# Middleware that looks for a 'trace.serialized' parameter and puts it in a 
# 'X-Honeycomb-Trace' header if found. This allows Honeycomb Beeline to continue 
# traces propagated from an external source (e.g Javascript). 
#
# See here for where the Beeline uses that header:
# https://github.com/honeycombio/beeline-ruby/blob/6db9d6e0f696d93212100cca5efdeefc7723afb7/lib/honeycomb/integrations/rack.rb#L35
#
# This is intended to be used by Javascript and any other external service that needs to send
# Honeycomb events / spans as part of an already started Honeycomb::Trace
module Honeycomb
  module TracePropagation
  
    def initialize app
      @app = app
    end
  
    def call(env)
      req = ::Rack::Request.new(env)

      # This param is added by our Boomerang plugin on every beacon sent from Javascript
      trace_serialized = req.params['trace.serialized'] 
      env["HTTP_X_HONEYCOMB_TRACE"] = trace_serialized if trace_serialized

      @app.call(env)
    end

    class Middleware
      include TracePropagation
    end 

  end
end


require 'lti_launch'
require 'filter_logging'

# Used for filtering out the parameters that you don't want shown in the logs,
# such as passwords or credit card numbers.
if FilterLogging.is_enabled? 

  Rails.application.config.filter_parameters << FilterLogging.filter_parameters

  # TODO: this filters the whole redirect path. We just want to filter the state or auth params.
  # Look into monkey patching the filtered_location method here:
  # https://github.com/rails/rails/blob/291a3d2ef29a3842d1156ada7526f4ee60dd2b59/actionpack/lib/action_dispatch/http/filter_redirect.rb#L8

  # Filter logs that say "Redirected to <blah_path>/state=<the_state_value>" as well.
  Rails.application.config.filter_redirect.concat [/state\=([^\&]+)/, /auth\=([^\&]+)/]

  # TODO: this doesn't seem to work
  # Filter database SQL queries as well.
  LtiLaunch.filter_attributes = [:state]

end

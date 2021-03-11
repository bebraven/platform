require 'filter_logging'
require 'lti_launch'

# Used for filtering out the parameters that you don't want shown in the logs,
# such as passwords or credit card numbers.
if FilterLogging.is_enabled? 

  Rails.application.config.filter_parameters << FilterLogging.filter_parameters

  # Note: instead of using the following to filter the "Redirected to <some_path>" logs,
  # see lib/core_ext/filter_redirect.rb for how we do that since this is meant for filtering
  # the entire path out.
  # Rails.application.config.filter_redirect.concat [/state\=([^\&]+)/, /auth\=([^\&]+)/]

  # TODO: this doesn't seem to work
  # Filter database SQL queries as well.
  LtiLaunch.filter_attributes = [:state]

end

require 'filter_logging'

# Used for changing the behavior of ActionDispatch::Http::FilterRedirect
# so that it only filters out the sensitive information from the redirect to
# location and not the whole path.
if FilterLogging.is_enabled?
  require "action_dispatch"
  require 'core_ext/filter_redirect'

  # Note that ActionDispatch::Http::FilterRedirect is included in ActionDispatch::Response,
  # so we're prepending our module to overwrite the behavior.
  ActionDispatch::Response.prepend CoreExtensions::FilterRedirect::ParametersOnly
end

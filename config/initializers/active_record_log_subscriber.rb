require 'filter_logging'

# Used for changing the behavior of ActiveRecord::LogSubscriber
# so that it filters out the sensitive information when logging
if FilterLogging.is_enabled?
  require "active_record"
  require 'core_ext/active_record_log_subscriber'

  ActiveRecord::LogSubscriber.prepend CoreExtensions::ActiveRecord::LogSubscriber
end

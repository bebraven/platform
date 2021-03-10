Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Compress CSS using a preprocessor.
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :amazon

  # Mount Action Cable outside main process or domain.
  # config.action_cable.mount_path = nil
  # config.action_cable.url = 'wss://example.com/cable'
  # config.action_cable.allowed_request_origins = [ 'http://example.com', /http:\/\/example.*/ ]

  # Used for filtering out the parameters that you don't want shown in the logs,
  # such as passwords or credit card numbers.
  # Note that I tried several ways of doing this, but this is what ended up
  # working. Taken from here: https://stackoverflow.com/questions/28414886/can-i-customize-the-way-that-rails-filters-a-parameter
  config.filter_parameters << lambda do |param_name, value|

    # Note: we have to alter the strings in place because we don't have access to 
    # the hash to update the key's value
    if param_name == 'state' || param_name == 'password' # TODO: add auth for the index.html call?
      value.clear()
      value.insert(0, '[FILTERED]')

    elsif param_name == 'u'
      # HoneycombJsController example:
      # "u"=>"https://platformweb/rise360_module_versions/18?state=[FILTERED]"
      value.gsub!(/state\=([^\&]+)/, 'state=[FILTERED]')

    elsif param_name == 'restiming'
      # HoneycombJsController example:
      # "restiming"=>"{\"https://\":{\"platformweb\":{\"/\":{\"rise360_\":{\"module_versions/18?state=[FILTERED]\":
      # \"6,2b7,2b7,4x,4w,4w,4w,4w,4w,4w,2*127w,1qb\",\"proxy/lessons/sxj0v0dsxa8qykfv36n1citzh6jz/\":
      # {\"index.html?actor=%7B%22name%22%3A%22RISE360_USERNAME_REPLACE%22%2C%20%22mbox%22%3A%5B%22mailto%3ARISE360_PASSWORD_REPLACE%22%5D%7D&
      # auth=[FILTERED]&endpoint=https%3A%2F%2Fplatformweb%2Fdata%2FxAPI\"
      value.gsub!(/auth\=LtiState([^\"\&]+)/, 'auth=[FILTERED]')
      value.gsub!(/state\=([^\"\&]+)/, 'state=[FILTERED]')

    end

  end
  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true if ENV['FORCE_SSL'].present?

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = ENV.fetch('LOG_LEVEL') { :debug }

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment).
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "platform_production"

  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = { host: Rails.application.secrets.application_host, protocol: 'https' }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    :address              => Rails.application.secrets.smtp_server,
    :port                 => Rails.application.secrets.smtp_port,
    :domain               => Rails.application.secrets.smtp_domain,
    :user_name            => Rails.application.secrets.smtp_username,
    :password             => Rails.application.secrets.smtp_password,
    :authentication       => :login
  }

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Use a different logger for distributed setups.
  # require 'syslog/logger'
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Inserts middleware to perform automatic connection switching.
  # The `database_selector` hash is used to pass options to the DatabaseSelector
  # middleware. The `delay` is used to determine how long to wait after a write
  # to send a subsequent read to the primary.
  #
  # The `database_resolver` class is used by the middleware to determine which
  # database is appropriate to use based on the time delay.
  #
  # The `database_resolver_context` class is used by the middleware to set
  # timestamps for the last write to the primary. The resolver uses the context
  # class timestamps to determine how long to wait before reading from the
  # replica.
  #
  # By default Rails will store a last write timestamp in the session. The
  # DatabaseSelector middleware is designed as such you can define your own
  # strategy for connection switching and pass that into the middleware through
  # these configuration options.
  # config.active_record.database_selector = { delay: 2.seconds }
  # config.active_record.database_resolver = ActiveRecord::Middleware::DatabaseSelector::Resolver
  # config.active_record.database_resolver_context = ActiveRecord::Middleware::DatabaseSelector::Resolver::Session
end

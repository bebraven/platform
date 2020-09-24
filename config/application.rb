require_relative 'boot'

require 'rails/all'

require_relative '../lib/lti_rise360_proxy'
require_relative '../lib/honeycomb_trace_propagation'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Platform
  class Application < Rails::Application

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Determines whether forgery protection is added on ActionController:Base. This is false by default to
    # be backwards compatible with v5.2 and below who may have removed it from ApplicationController
    config.action_controller.default_protect_from_forgery = true

    # Allows us to serve Rise360 static files hosted on AWS S3 through our server avoiding browser cross-origin issues.
    config.middleware.use LtiRise360Proxy, backend: "https://#{Rails.application.secrets.aws_files_bucket}.s3.amazonaws.com"

    # Allows us to continue Honeycomb traces propagated from an external source, like client-side Javascript.
    # Note that this needs to come before Honeycomb::Rack::Middleware to work (but that's inserted after this runs).
    config.middleware.insert_after(ActionDispatch::RequestId, Honeycomb::TracePropagation::Middleware)

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Allow `bundle exec rake assets:precompile` without loading the whole rails app. 
    # E.g. if we want to run in production mode locally.
    #config.assets.initialize_on_precompile=false
  end

end

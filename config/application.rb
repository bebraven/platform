require_relative 'boot'

require 'rails/all'

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

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Allow `bundle exec rake assets:precompile` without loading the whole rails app. 
    # E.g. if we want to run in production mode locally.
    #config.assets.initialize_on_precompile=false
  end
end

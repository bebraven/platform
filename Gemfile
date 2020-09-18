# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.6.5'
gem 'rails', '~> 6.0.0'

gem 'pg'

# Use Puma as the app server
gem 'puma', '~> 3.12'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5'
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem 'webpacker', '~> 4.0'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.2', require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]

  gem 'dotenv'
  gem 'factory_bot_rails'
  gem 'rspec-rails', '~> 3.6'
  gem 'shoulda-matchers'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'web-console', '>= 3.3.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'

  # Require rack-livereload in development bc we use it in config/environments/development.rb.
  gem 'rack-livereload', require: true

  gem 'guard-livereload', require: false
  gem 'guard-rails', require: false
  gem 'guard-rspec', require: false
  gem 'guard-webpacker', require: false
  gem 'guard-yarn', require: false
  gem 'libnotify', require: false
  gem 'pry-rescue', require: false
  gem 'pry-stack_explorer', require: false
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'webpacker-react', '~> 1.0.0.beta.1'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'
  # Easy installation and use of web drivers to run system tests with browsers
  gem 'webdrivers'
  # HTTP request mocking
  gem 'webmock', require: false

  # Report test coverage
  gem 'simplecov', require: false
  gem 'simplecov-cobertura', require: false

  # Clean database after tests
  gem 'database_cleaner', require: false

  # Stores mocks in reusable file
  gem 'vcr'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

gem 'bulk_insert'
gem 'paranoia'
gem 'will_paginate'

gem 'rest-client'

gem 'devise'
gem 'devise_cas_authenticatable'

gem 'react-rails'

gem 'sentry-raven'

# Using a branch for a time being to remove R18n until we decide what we want to do
gem 'rubycas-server-activerecord'
gem 'rubycas-server-core', github: 'bebraven/rubycas-server-core', branch: 'platform-compat'

# Honeycomb
gem 'honeycomb-beeline'

# Allows us to write rake tasks that can programatticaly run Heroku commands
# using their API. E.g. create a task to restart a dyno so it can be run
# in the middle of the night to avoid downtime when users are on the platform
# See: https://github.com/heroku/platform-api
gem 'platform-api', require: false

# To develop locally, you can mount your local rowan_bot code as a volume in docker-compose.yml
# and then change the following to this:
# gem 'rowan_bot', path: '/app/rowan_bot'
gem 'rowan_bot', github: 'bebraven/rowan_bot', ref: 'b078c0f'

# Implementation of JSON Web Token (JWT) standard: https://github.com/jwt/ruby-jwt
gem 'jwt'

# Generates attr_accessors that encrypt and decrypt attributes transparently in the database
gem 'attr_encrypted'

gem 'aws-sdk-s3'
gem 'rubyzip'

gem 'rails_same_site_cookie'

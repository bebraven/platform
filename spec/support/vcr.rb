require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.ignore_hosts ENV['SELENIUM_HOST'] if ENV['SELENIUM_HOST']
  config.ignore_localhost = true
  # Only put third-party hosts we don't care about below. Things we do actually care about the
  # responses should be VCR-recorded instead.
  config.ignore_hosts 'chromedriver.storage.googleapis.com', 'api.codacy.com', 'api.honeycomb.io'
  # Need this to pass :vcr option to describe blocks.
  config.configure_rspec_metadata!
end

require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.ignore_hosts 'platformweb', 'stagingplatform.bebraven.org', 'platform.bebraven.org', 'chromedriver.storage.googleapis.com', 'api.codacy.com'
  config.ignore_hosts ENV['SELENIUM_HOST'] if ENV['SELENIUM_HOST']
  config.ignore_localhost = true
end

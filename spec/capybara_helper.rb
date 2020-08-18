RSpec.configure do |config|
  config.include Capybara::DSL
end

# This is the host and port that Capybara makes the server
# running the specs listen on. Needed if an external service will callback
# into the test server (aka Selenium tests need this if running in Docker).
Capybara.server_host = ENV['SPEC_HOST'] if ENV['SPEC_HOST']
Capybara.server_port = ENV['SPEC_PORT'] if ENV['SPEC_PORT']

Capybara.threadsafe = true # Allows us to change config on a per session basis.

chrome_shim = ENV.fetch('GOOGLE_CHROME_SHIM', nil)
chrome_host = ENV.fetch('SELENIUM_HOST', nil)

# This is for Heroku. See: https://elements.heroku.com/buildpacks/heroku/heroku-buildpack-google-chrome
if chrome_shim
  Selenium::WebDriver::Chrome.path = chrome_shim

  chrome_opts = chrome_shim ? { "chromeOptions" => { "binary" => chrome_shim, "remote-debugging-port" => "9222", "headless" => true } } : {}
  puts chrome_opts

  Capybara.register_driver :chrome do |app|
    Capybara::Selenium::Driver.new(
      app,
      browser: :chrome,
      desired_capabilities: Selenium::WebDriver::Remote::Capabilities.chrome(chrome_opts)
    )
  end

  Capybara.javascript_driver = :chrome
elsif chrome_host # If you're running it in a docker container and have to connect to another container with chome installed.

  chrome_opts = ['--headless', '--no-sandbox', '--disable-gpu', '--remote-debugging-port=9222', '--disable-dev-shm-usage', '--disable-extensions', '--disable-features=VizDisplayCompositor', '--enable-features=NetworkService,NetworkServiceInProcess']

  # Note: the goog:chromeOptions namespace is in case you switch to connect to a Selenium HUB instead of a standalone.
  # For some reason, things fail against the hub without the "goog" namespace.
  caps = Selenium::WebDriver::Remote::Capabilities.chrome("goog:chromeOptions" => {"args" => chrome_opts})
  Capybara.register_driver :selenium do |app|
    Capybara::Selenium::Driver.new(
        app,
        browser: :remote,
        url: "http://#{ENV['SELENIUM_HOST']}:#{ENV['SELENIUM_PORT']}/wd/hub",
        desired_capabilities: caps
    )
  end

  Capybara.javascript_driver = :selenium
  
else # Assumes your running it on localhost and have Chrome installed on your machine.
  Capybara.javascript_driver = :selenium_chrome_headless
end



# frozen_string_literal: true

require 'slack-ruby-client'
require 'capybara/dsl'
require 'selenium-webdriver'

module RowanBot
  # SlackAPI class for slack stuff
  class SlackAPI
    include Capybara::DSL

    def initialize(params = {})
      chrome_shim = params.fetch(:chrome_shim, ENV.fetch('GOOGLE_CHROME_SHIM', nil))
      chrome_host = params.fetch(:chrome_host, ENV.fetch('SELENIUM_HOST', nil))

      # This is for Heroku. See: https://elements.heroku.com/buildpacks/heroku/heroku-buildpack-google-chrome
      if chrome_shim
        chrome_opts = chrome_shim ? { "chromeOptions" => { "binary" => chrome_shim } } : {}
        
        Capybara.register_driver :chrome do |app|
          Capybara::Selenium::Driver.new(
             app,
             browser: :chrome,
             desired_capabilities: Selenium::WebDriver::Remote::Capabilities.chrome(chrome_opts)
          )
        end

        Capybara.default_driver = :chrome

      elsif chrome_host # If you're running it in a docker container and have to connect to another container with chome installed.

        chrome_opts = ['--headless', '--no-sandbox', '--disable-gpu', '--remote-debugging-port=9222', '--disable-dev-shm-usage', '--disable-extensions', '--disable-features=VizDisplayCompositor', '--enable-features=NetworkService,NetworkServiceInProcess']

        # Note: the goog:chromeOptions namespace is in case you switch to connect to a Selenium HUB instead of a standalone.
        # For some reason, things fail against the hub without the "goog" namespace.
        caps = Selenium::WebDriver::Remote::Capabilities.chrome('goog:chromeOptions' => { 'args' => chrome_opts })
        Capybara.register_driver :selenium do |app|
          Capybara::Selenium::Driver.new(
            app,
            browser: :remote,
            url: "http://#{params.fetch(:selenium_host, ENV['SELENIUM_HOST'])}:#{params.fetch(:selenium_port, ENV['SELENIUM_PORT'])}/wd/hub",
            desired_capabilities: caps
          )
        end

        Capybara.default_driver = :selenium

      else # Assumes your running it on localhost and have Chrome installed on your machine.
        Capybara.default_driver = :selenium_chrome
      end

      Capybara.match = :first

      Slack.configure do |config|
        config.token = params.fetch(:slack_token, ENV['SLACK_TOKEN'])
      end

      @client = Slack::Web::Client.new
      @slack_user = params.fetch(:slack_user, ENV['SLACK_USER'])
      @slack_password = params.fetch(:slack_password, ENV['SLACK_PASSWORD'])
      @slack_url = params.fetch(:slack_url, ENV['SLACK_URL'])
    end

    def send_onboarding_notification(emails)
      message = "These users just signed their waivers: #{emails}"
      client.chat_postMessage(channel: '#on-boarding-notifications', text: message)
    end

    def create_peer_group_channels(names)
      channels = client.conversations_list(types: 'public_channel,private_channel').channels
      to_create = []
      existing = names.map do |name|
        schan = channels.find { |chan| chan.name.eql?(name) }
        if schan.nil?
          to_create << name
          nil
        else
          { name: schan.name, id: schan.id }
        end
      end.compact

      created = to_create.map do |name|
        channel = client.conversations_create(name: name, is_private: true).channel
        logger.info("Created channel #{name}")
        { name: channel.name, id: channel.id }
      end

      [existing + created, created]
    end

    def add_users_to_peer_group_channel(channel_id, user_ids)
      logger.info("Adding users to #{channel_id}")
      client.conversations_invite(channel: channel_id, users: user_ids.join(','))
    end

    def remove_user_from_channel(channel_id, user_id)
      logger.info("Remove user from #{channel_id}")
      client.conversations_kick(channel: channel_id, user: user_id)
    end

    def get_channel_members(channel_id)
      client.conversations_members(channel: channel_id).members
    end

    def add_slack_ids_to_users(users)
      slack_users = []
      client.users_list { |response| slack_users.concat(response.members) }
      users.map do |user|
        slack_user = slack_users.find { |slack_u| slack_u.profile.email.eql?(user[:email]) }
        raise "Slack user #{user[:email]} is not in this workspace" if slack_user.nil?

        logger.info("Found user #{user[:email]}")
        user[:slack_id] = slack_user.id
        user
      end
    end

    def invite_users_to_slack(emails)
      return if emails.empty?

      login_to_slack
      emails = emails.join(', ')
      logger.info("Adding users: #{emails}")

      click_on('People')
      click_on('Invite People')
      click_on('add many at once')
      fill_in('bulk-invites-input', with: emails)
      click_on('Add Invitees')
      click_on('Send Invitations')
    end

    private

    attr_reader :client, :slack_user, :slack_password, :slack_url

    def login_to_slack
      logger.info('Logging into slack')
      visit slack_url
      fill_in('email', with: slack_user)
      fill_in('password', with: slack_password)
      click_on('signin_btn')
    end

    def logger
      RowanBot.logger
    end
  end
end

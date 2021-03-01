# frozen_string_literal: true

require 'faraday'
require 'json'

module RowanBot
  # ZoomAPI class to wrap around the zoom API
  class ZoomAPI
    BASE_URL = 'https://api.zoom.us/v2'

    def initialize
      @token = ENV['ZOOM_TOKEN']
    end

    def create_meeting(user_id, data)
      logger.info("Creating a meeting: #{data['topic']}")
      url = "#{BASE_URL}/users/#{user_id}/meetings"

      post(url, data)
    end

    def add_registrant(meeting_id, data)
      logger.info("Adding zoom registrant: #{data['email']}")
      url = "#{BASE_URL}/meetings/#{meeting_id}/registrants"

      post(url, data)
    end

    def cancel_registrants(meeting_id, registrants)
      logger.info("Cancelling registration for: #{registrants.join(', ')}")
      registrants = registrants.map { |registrant| {'email' => registrant } }
      url = "#{BASE_URL}/meetings/#{meeting_id}/registrants/status"
      data = { 'action' => 'cancel', 'registrants' => registrants }

      put(url, data)
    end

    def update_meeting_for_registration(meeting_id)
      logger.info("Updating meeting for registration: #{meeting_id}")
      url = "#{BASE_URL}/meetings/#{meeting_id}"
      data = {
        'settings' => {
          'approval_type' => 0,
          'registration_type' => 2,
          'registrants_email_notification' => false,
          'registrants_confirmation_email' => false
        }
      }

      patch(url, data)
    end

    private

    attr_reader :token

    def fetch(url, params = {})
      response = Faraday.get(url, params, shared_headers)

      extract_response(response)
    end

    def post(url, data)
      response = Faraday.post(url, data.to_json, shared_headers)

      extract_response(response)
    end

    def patch(url, data)
      response = Faraday.patch(url, data.to_json, shared_headers)

      extract_response(response)
    end

    def put(url, data)
      response = Faraday.put(url, data.to_json, shared_headers)

      extract_response(response)
    end

    def extract_response(response)
      unless [201, 200, 204].include?(response.status)
        logger.warn('Request to zoom was not successful')
        logger.error(response.body)
        raise "Something went wrong communicating with zoom: #{response.body}"
      end

      JSON.parse(response.body) unless response.body.empty?
    end

    def shared_headers
      {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{token}"
      }
    end

    def logger
      RowanBot.logger
    end
  end
end

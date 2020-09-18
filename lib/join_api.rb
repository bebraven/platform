# frozen_string_literal: true

require 'rest-client'

# API to the join server
class JoinAPI
  JoinUser = Struct.new(:id, :email)

  def self.client
    new(Rails.application.secrets.join_base_url,
        Rails.application.secrets.join_api_token)
  end

  def initialize(base_endpoint, token)
    @base_api_endpoint = "#{base_endpoint}/api"
    @global_headers = { 'Authorization' => "Bearer #{token}" }
  end

  def find_user_by(email:)
    response = request(method: :get, path: 'users', params: { q: email })
    return nil if response.empty?

    make_user_response(response.first)
  end

  def create_user(email:, first_name:, last_name:)
    data = { user: { email: email, first_name: first_name, last_name: last_name } }
    response = request(method: :post, path: 'users', body: data)

    make_user_response(response)
  end

  private

  attr_reader :base_api_endpoint, :global_headers

  def make_user_response(response)
    JoinUser.new(response['id'], response['email'])
  end

  def request(method:, path:, body: {}, params: {})
    headers = global_headers.merge({ params: params })
    url = "#{base_api_endpoint}/#{path}"
    response = RestClient::Request.execute(method: method, url: url,
                                           payload: body, headers: headers)
    JSON.parse(response.body)
  end
end

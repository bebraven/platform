# frozen_string_literal: true
require 'json'
require 'rest-client'
require 'uri'

# This class handles communicating with the LinkedIn's authorization flow:
#  https://docs.microsoft.com/en-us/linkedin/shared/authentication/authorization-code-flow
# and LinkedIn's API:
#  https://docs.microsoft.com/en-us/linkedin/shared/api-guide/concepts
# behalf fo the Braven's LinkedIn app: 
#  https://www.linkedin.com/developers/apps/5004876
class LinkedInAPI
  AUTHORIZATION_URL = 'https://www.linkedin.com/oauth/v2/authorization'
  ACCESS_TOKEN_URL = 'https://www.linkedin.com/oauth/v2/accessToken'
  API_URL = 'https://api.linkedin.com/'

  # Generate LinkedIn authorization URL to present to user
  # See: https://docs.microsoft.com/en-us/linkedin/shared/authentication/authorization-code-flow
  def self.authorize_url(redirect_url, state)
    url = Addressable::URI.parse(AUTHORIZATION_URL)
    url.query = {
      client_id: Rails.application.secrets.linked_in_client_id,
      redirect_uri: redirect_url,
      scope: 'r_emailaddress r_fullprofile',
      response_type: 'code',
      state: state,
    }.to_query
    url.to_s
  end

  # Exchange authorization code for access token with LinkedIn
  # See: https://docs.microsoft.com/en-us/linkedin/shared/authentication/authorization-code-flow#step-3-exchange-authorization-code-for-an-access-token
  def self.exchange_code_for_token(redirect_url, authorization_code)
    response = RestClient.post(
      ACCESS_TOKEN_URL,
      {
        client_id: Rails.application.secrets.linked_in_client_id,
        client_secret: Rails.application.secrets.linked_in_client_secret,
        code: authorization_code,
        grant_type: 'authorization_code',
        redirect_uri: redirect_url,
      },
    )
    body = JSON.parse(response.body)
    body['access_token']
  end

  # Example: 
  #   LinkedInConnection::get_request('/v2/me', user.linked_in_access_token)
  # See: https://developer.linkedin.com/docs/fields/full-profile
  def self.get_request(path, access_token)
    response = RestClient.get(
      Addressable::URI.join(API_URL, path).to_s,
      {Authorization: "Bearer #{access_token}"},
    )
    JSON.parse(response.body)
  end
end

require 'rails_helper'
require 'linked_in_api'
require 'uri'

RSpec.describe LinkedInAPI do
  describe '#authorize_url' do
    it 'returns the expected url' do
      redirect_url = 'https://platformweb/linked_in/auth'
      state = rand().to_s

      authorization_url = LinkedInAPI.authorize_url(
        redirect_url,
        state,
      )

      url = Addressable::URI.parse(authorization_url)
      expect(url.omit(:query).to_s).to eq(
        LinkedInAPI::AUTHORIZATION_URL,
      )
      expect(url.query_values['redirect_uri']).to eq(redirect_url)
      expect(url.query_values['state']).to eq(state)
    end
  end

  describe '#exchange_code_for_token' do
    it 'calls the correct LinkedIn authorization endpoint' do
      redirect_url = 'https://platformweb/linked_in/auth'
      authorization_code = 'some-authorization-code'
      expected_access_token = 'some-access-token'

      stub_request(:post, LinkedInAPI::ACCESS_TOKEN_URL)
        .with(body: hash_including({
          redirect_uri: redirect_url,
          code: authorization_code,
        }))
        .to_return(body: {access_token: expected_access_token}.to_json) 

      access_token = LinkedInAPI.exchange_code_for_token(
        redirect_url,
        authorization_code,
      )

      expect(WebMock)
        .to have_requested(:post, LinkedInAPI::ACCESS_TOKEN_URL)
        .once
      expect(access_token).to eq(expected_access_token)
    end
  end

  describe '#get_request' do 
    it 'calls the correct LinkedIn API endpoint' do
      access_token = 'some-access-token'
      path = '/v2/me'
      request_url = Addressable::URI.join(LinkedInAPI::API_URL, path).to_s

      stub_request(:get, request_url)
        .to_return(body: {data: 'some-dummy-data'}.to_json)

      data = LinkedInAPI.get_request(path, access_token)

      expect(WebMock)
        .to have_requested(:get, request_url)
        .with(headers: {Authorization: "Bearer #{access_token}"})
        .once
    end
  end
end

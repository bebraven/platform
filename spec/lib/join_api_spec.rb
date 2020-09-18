# frozen_string_literal: true

require 'rails_helper'
require 'join_api'

RSpec.describe JoinAPI do
  WebMock.disable_net_connect!

  let(:join_api_base_path) { "#{Rails.application.secrets.join_base_url}/api" }
  let(:join_api_client) { described_class.client }

  describe '#find_user_by' do
    let(:join_user_index_path) { "#{join_api_base_path}/users" }
    let(:test_email) { 'test@example.com' }

    it 'hits the join api with right auth headers' do
      stub_request(:get, join_user_index_path).with(query: { 'q' => test_email }).to_return(body: [].to_json)

      join_api_client.find_user_by(email: test_email)

      expect(WebMock).to have_requested(:get, join_user_index_path)
        .with(query: { 'q' => test_email }, headers: { 'Authorization' => "Bearer #{Rails.application.secrets.join_api_token}" }).once
    end

    it 'returns user when user is on join' do
      stub_request(:get, join_user_index_path).with(query: { 'q' => test_email }).to_return(body: [{ id: 1, email: test_email }].to_json)

      response = join_api_client.find_user_by(email: test_email)
      expect(response.email).to eql(test_email)
    end

    it 'returns nil when user is not on join' do
      stub_request(:get, join_user_index_path).with(query: { 'q' => test_email }).to_return(body: [].to_json)

      response = join_api_client.find_user_by(email: test_email)

      expect(response).to be_nil
    end
  end

  describe '#create_user' do
    let(:join_user_create_path) { "#{join_api_base_path}/users" }

    it 'hits the join api with right auth headers' do
      test_email = 'test@example.com'
      stub_request(:any, join_user_create_path).to_return(body: { email: test_email, id: 1 }.to_json)

      join_api_client.create_user(email: test_email, first_name: 'first_name', last_name: 'last_name')

      expect(WebMock).to have_requested(:post, join_user_create_path)
        .with(headers: { 'Authorization' => "Bearer #{Rails.application.secrets.join_api_token}" }).once
    end

    it 'returns user when successful' do
      test_email = 'test@example.com'
      stub_request(:any, join_user_create_path).to_return(body: { email: test_email, id: 1 }.to_json)

      response = join_api_client.create_user(email: test_email, first_name: 'first_name', last_name: 'last_name')

      expect(response.email).to eql(test_email)
    end

    it 'raises error when there is an error' do
      stub_request(:any, join_user_create_path).to_return(status: [500, 'Internal Server Error'])

      expect { join_api_client.create_user(email: 'test@email.com', first_name: 'first_name', last_name: 'last_name') }.to raise_error RestClient::InternalServerError
    end
  end
end

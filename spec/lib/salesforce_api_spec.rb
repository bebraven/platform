require 'rails_helper'
require 'salesforce_api'

RSpec.describe SalesforceAPI do

  before(:all) do

    ENV['SALESFORCE_HOST'] = 'test.salesforce.com'
    ENV['SALESFORCE_PLATFORM_CONSUMER_KEY'] = 'testkey'
    ENV['SALESFORCE_PLATFORM_CONSUMER_SECRET'] = 'testsecret'
    ENV['SALESFORCE_PLATFORM_USERNAME'] = 'testuser@example.com'
    ENV['SALESFORCE_PLATFORM_PASSWORD'] = 'testpassword' 
    ENV['SALESFORCE_PLATFORM_SECURITY_TOKEN'] = 'testtoken'
    SALESFORCE_LOGIN_URL = "https://#{ENV['SALESFORCE_HOST']}"
    SALESFORCE_INSTANCE_URL = 'https://test--staging22.bebraven.org'  

    WebMock.disable_net_connect!
  end

  before(:each) do
    login_response = { 'instance_url' => SALESFORCE_INSTANCE_URL, 'access_token' => 'test-token' }.to_json
    stub_request(:post, "#{SALESFORCE_LOGIN_URL}/services/oauth2/token").to_return(body: login_response )
  end

  describe '.client' do
    let(:salesforce) { SalesforceAPI.client }

    it 'gets an access token' do
      SalesforceAPI.client

      expect(WebMock).to have_requested(:post, "#{SALESFORCE_LOGIN_URL}/services/oauth2/token")
        .with(body: 'grant_type=password&client_id=testkey&client_secret=testsecret&username=testuser%40example.com&password=testpasswordtesttoken').once
    end

    it 'sets the authorization header' do
      stub_request(:any, /#{SALESFORCE_INSTANCE_URL}.*/)
      salesforce.get('/test')

      expect(WebMock).to have_requested(:get, "#{SALESFORCE_INSTANCE_URL}/test")
        .with(headers: {'Authorization'=>'Bearer test-token'}).once
    end
    
  end

  describe '#get_program_info(course_id)' do
    let(:salesforce) { SalesforceAPI.client }
    let(:course_id) { 71 }

    it 'calls the correct endpoint' do
      request_url_regex = /#{SALESFORCE_INSTANCE_URL}\/services\/data\/.*/
      program_json = FactoryBot.json(:salesforce_program)
      stub_request(:get, request_url_regex).to_return(body: program_json )

      response = salesforce.get_program_info(course_id)

      expect(WebMock).to have_requested(:get, request_url_regex).once
      expect(response).to eq(JSON.parse(program_json)['records'][0])
    end
  end

  describe '#get_participants(course_id)' do
    let(:salesforce) { SalesforceAPI.client }
    let(:course_id) { 71 }

    it 'calls the correct endpoint' do
      request_url = "#{SALESFORCE_INSTANCE_URL}/services/apexrest/participants/currentandfuture/?course_id=#{course_id}" 
      participant_json = "[#{FactoryBot.json(:salesforce_participant_fellow)}]"
      stub_request(:get, request_url).to_return(body: participant_json)

      response = salesforce.get_participants(course_id)

      expect(WebMock).to have_requested(:get, request_url).once
      expect(response).to eq(JSON.parse(participant_json))
    end
  end

  describe '#get_contact_info(contact_id)' do
    let(:salesforce) { SalesforceAPI.client }
    let(:contact_id) { '003170000125IpSAAU' }

    it 'calls the correct endpoint' do
      contact_json = FactoryBot.json(:salesforce_contact)
      request_url_regex = /#{SALESFORCE_INSTANCE_URL}\/services\/data\/v48.0\/sobjects\/Contact\/#{contact_json['id']}.*/
      stub_request(:get, request_url_regex).to_return(body: contact_json )

      response = salesforce.get_contact_info(contact_json['id'])

      expect(WebMock).to have_requested(:get, request_url_regex).once
      expect(response).to eq(JSON.parse(contact_json))
    end
  end

end

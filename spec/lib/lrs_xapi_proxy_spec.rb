require 'rails_helper'
require 'lrs_xapi_proxy'

RSpec.describe LrsXapiProxy do

  before(:all) do
    WebMock.disable_net_connect!
  end

  describe '.request' do
    let(:request) { ActionDispatch::TestRequest.create }
    let(:path) { 'test_endpoint' }
    let(:user) { create(:admin_user) }
    let(:url) { "#{Rails.application.secrets.lrs_url}/#{path}" }

    before(:each) do
      stub_request(:any, /^#{url}.*/)
      allow(request).to receive(:query_parameters).and_return(query_parameters.with_indifferent_access)
      allow(request).to receive(:request_parameters).and_return(request_parameters.with_indifferent_access)
      allow(request).to receive(:method).and_return(method)
      LrsXapiProxy.request(request, path, user)
    end

    context 'GET with no parameters' do
      let(:query_parameters) {{ }}
      let(:request_parameters) {{ }}
      let(:method) { 'GET' }

      it 'makes a basic get request with no params' do
        expect(WebMock).to have_requested(:get, url).once
      end
    end

    context 'PUT with no parameters' do
      let(:query_parameters) {{ }}
      let(:request_parameters) {{ }}
      let(:method) { 'PUT' }

      it 'makes a basic put request with no body' do
        expect(WebMock).to have_requested(:put, url)
          .with(body: {}).once
      end
    end

    context 'POST with no parameters' do
      let(:query_parameters) {{ }}
      let(:request_parameters) {{ }}
      let(:method) { 'POST' }

      it 'returns without requesting' do
        expect(WebMock).not_to have_requested(:any, /.*/)
      end
    end

    context 'GET with minimal parameters' do
      let(:query_parameters) {{ 'statementId': 'test' }}
      let(:request_parameters) {{ }}
      let(:method) { 'GET' }

      it 'makes a get request with original params' do
        expect(WebMock).to have_requested(:get, url)
          .with(query: query_parameters).once
      end
    end

    context 'PUT with minimal parameters' do
      let(:query_parameters) {{ 'statementId': 'test' }}
      let(:request_parameters) {{ 'testParam': 'test' }}
      let(:method) { 'PUT' }

      it 'makes a put request with original body and params' do
        expect(WebMock).to have_requested(:put, url)
          .with(body: request_parameters, query: query_parameters).once
      end
    end

    context 'with nested lrs_xapi_proxy params' do
      let(:query_parameters) {{ 'statementId': 'test' }}
      let(:request_parameters) {{
        'testParam1': 'test1',
        'testParam2': 'test2',
        'lrs_xapi_proxy': {
          'testParam1': 'test3',
          'testParam2': 'test4',
        },
      }}
      let(:method) { 'PUT' }

      it 'uses the nested params' do
        expect(WebMock).to have_requested(:put, url)
          .with(body: request_parameters[:lrs_xapi_proxy].to_json, query: query_parameters).once
      end
    end

    context 'with an actor' do
      let(:query_parameters) {{ 'statementId': 'test' }}
      let(:request_parameters) {{
        'testParam1': 'test1',
        'testParam2': 'test2',
        'actor': {
          'name': 'Replaced',
          'mbox': 'mailto:replaced@example.com',
        },
      }}
      let(:method) { 'PUT' }

      it 'overwrites the actor' do
        expected_body = {
          'testParam1': 'test1',
          'testParam2': 'test2',
          'actor': {
            'name': user.full_name,
            'mbox': "mailto:#{user.email}",
          },
        }.to_json

        expect(WebMock).to have_requested(:put, url)
          .with(body: expected_body, query: query_parameters).once
      end
    end

    context 'with an agent' do
      let(:query_parameters) {{
        'statementId': 'test',
        'agent': {
          'name': 'Replaced',
          'mbox': 'mailto:replaced@example.com',
          'objectType': 'Agent',
        }.to_json,
      }}
      let(:request_parameters) {{
        'testParam1': 'test1',
        'testParam2': 'test2',
      }}
      let(:method) { 'PUT' }

      it 'overwrites the agent' do
        expected_query = {
          'statementId': 'test',
          'agent': {
            'name': user.full_name,
            'mbox': "mailto:#{user.email}",
            'objectType': 'Agent',
          }.to_json,
        }

        expect(WebMock).to have_requested(:put, url)
          .with(body: request_parameters.to_json, query: expected_query).once
      end
    end

    context 'with a NaN duration' do
      let(:query_parameters) {{ 'statementId': 'test' }}
      let(:request_parameters) {{
        'testParam1': 'test1',
        'testParam2': 'test2',
        'result': {
          'duration': 'PTNaNS',
        },
      }}
      let(:method) { 'PUT' }

      it 'replaces the duration with 0.0' do
        expected_body = {
          'testParam1': 'test1',
          'testParam2': 'test2',
          'result': {
            'duration': 'PT0.0S',
          },
        }.to_json

        expect(WebMock).to have_requested(:put, url)
          .with(body: expected_body, query: query_parameters).once
      end
    end

    context 'with a valid duration' do
      let(:query_parameters) {{ 'statementId': 'test' }}
      let(:request_parameters) {{
        'testParam1': 'test1',
        'testParam2': 'test2',
        'result': {
          'duration': 'PT0.6S',
        },
      }}
      let(:method) { 'PUT' }

      it 'passes the duration through unchanged' do
        expect(WebMock).to have_requested(:put, url)
          .with(body: request_parameters.to_json, query: query_parameters).once
      end
    end


    context 'when the upstream returns a 404' do
      let(:query_parameters) {{ }}
      let(:request_parameters) {{ }}
      let(:method) { 'GET' }

      it 'catches the exception and returns the response' do
        expect(RestClient::Request).to receive(:execute).and_raise(RestClient::NotFound.new('test'))
        response = LrsXapiProxy.request(request, path, user)
        # Ensure .request returns the result of .execute
        expect(response).to eq('test')
      end
    end

    context 'when the upstream returns a non-404 error' do
      let(:query_parameters) {{ }}
      let(:request_parameters) {{ }}
      let(:method) { 'GET' }

      it 're-raises the same exception' do
        expect(RestClient::Request).to receive(:execute).and_raise(RestClient::Exception)
        expect {
          response = LrsXapiProxy.request(request, path, user)
        }.to raise_error(RestClient::Exception)

        expect(RestClient::Request).to receive(:execute).and_raise(RestClient::BadRequest)
        expect {
          response = LrsXapiProxy.request(request, path, user)
        }.to raise_error(RestClient::BadRequest)
      end
    end
  end
end

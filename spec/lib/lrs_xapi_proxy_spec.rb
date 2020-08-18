require 'rails_helper'
require 'lrs_xapi_proxy'

RSpec.describe LrsXapiProxy do

  before(:all) do
    WebMock.disable_net_connect!
  end

  describe '.request' do
    let(:request) { ActionDispatch::TestRequest.create }
    let(:user) { create(:admin_user) }
    let(:url) { "#{Rails.application.secrets.lrs_url}/#{endpoint}" }
    let(:response_body) { '' }
    let(:response) { LrsXapiProxy.request(request, endpoint, user) }

    before(:each) do
      stub_request(:any, /^#{url}.*/).to_return(body: response_body)
      allow(request).to receive(:query_parameters).and_return(query_parameters.with_indifferent_access)
      allow(request).to receive(:raw_post).and_return(post_body) if method == 'PUT' || method == 'POST'
      allow(request).to receive(:method).and_return(method)
      response # This is what makes the request for each test and sets this to the response
    end

    context 'any endpoint' do
      let(:endpoint) { 'test_endpoint' }

      context 'GET with no parameters' do
        let(:query_parameters) {{ }}
        let(:method) { 'GET' }
  
        it 'makes a basic get request with no params' do
          expect(WebMock).to have_requested(:get, url).once
        end
      end

      context 'PUT with no parameters' do
        let(:query_parameters) {{ }}
        let(:post_body) {{ }.to_json}
        let(:method) { 'PUT' }
  
        it 'makes a basic put request with no body' do
          expect(WebMock).to have_requested(:put, url)
            .with(body: {}).once
        end
      end

      context 'POST with no parameters' do
        let(:query_parameters) {{ }}
        let(:post_body) {{ }.to_json}
        let(:method) { 'POST' }
  
        it 'returns without requesting' do
          expect(WebMock).not_to have_requested(:any, /.*/)
        end
      end

      context 'DELETE with no parameters' do
        let(:query_parameters) {{ }}
        let(:method) { 'DELETE' }
  
        it 'returns without requesting' do
          expect(WebMock).not_to have_requested(:any, /.*/)
        end
      end

      context 'when the upstream returns a 404' do
        let(:query_parameters) {{ }}
        let(:method) { 'GET' }
  
        it 'catches the exception and returns the response' do
          expect(RestClient::Request).to receive(:execute).and_raise(RestClient::NotFound.new('test'))
          response = LrsXapiProxy.request(request, endpoint, user)
          # Ensure .request returns the result of .execute
          expect(response).to eq('test')
        end
      end
  
      context 'when the upstream returns a non-404 error' do
        let(:query_parameters) {{ }}
        let(:method) { 'GET' }
  
        it 're-raises the same exception' do
          expect(RestClient::Request).to receive(:execute).and_raise(RestClient::Exception)
          expect {
            response = LrsXapiProxy.request(request, endpoint, user)
          }.to raise_error(RestClient::Exception)
  
          expect(RestClient::Request).to receive(:execute).and_raise(RestClient::BadRequest)
          expect {
            response = LrsXapiProxy.request(request, endpoint, user)
          }.to raise_error(RestClient::BadRequest)
        end
      end
  
      context 'with a user_override param' do
        let(:other_user) { create(:registered_user) }
        let(:query_parameters) {{
          'some_param': 'test',
          'user_override_id': other_user.id,
        }}
        let(:method) { 'GET' }
  
        it 'excludes the user_override param' do
          expect(WebMock).to have_requested(:get, url)
            .with(query: {'some_param': 'test'}).once
        end
      end

    end # context 'any endpoint'

    context 'xAPI statements endpoint' do
      let(:endpoint) { 'statements' }

      context 'GET with minimal parameters' do
        let(:query_parameters) {{ 'statementId': 'test' }}
        let(:method) { 'GET' }
  
        it 'makes a get request with original params' do
          expect(WebMock).to have_requested(:get, url)
            .with(query: query_parameters).once
        end
      end
  
      context 'PUT with minimal parameters' do
        let(:query_parameters) {{ 'statementId': 'test' }}
        let(:post_body) {{ 'testParam': 'test' }.to_json}
        let(:method) { 'PUT' }
  
        it 'makes a put request with original body and params' do
          expect(WebMock).to have_requested(:put, url)
            .with(body: post_body, query: query_parameters).once
        end
      end

      context 'with an actor' do
        let(:query_parameters) {{ 'statementId': 'test' }}
        let(:post_body) {{
          'testParam1': 'test1',
          'testParam2': 'test2',
          'actor': {
            'objectType': 'Agent',
            'name': 'Replaced',
            'mbox': 'mailto:replaced@example.com',
          },
        }.to_json }
        let(:method) { 'PUT' }
  
        it 'overwrites the actor' do
          expected_body = {
            'testParam1': 'test1',
            'testParam2': 'test2',
            'actor': {
              'objectType': 'Agent',
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
            'objectType': 'Agent',
            'name': 'Replaced',
            'mbox': 'mailto:replaced@example.com',
          }.to_json,
        }}
        let(:post_body) {{
          'testParam1': 'test1',
          'testParam2': 'test2',
        }.to_json}
        let(:method) { 'PUT' }
  
        it 'overwrites the agent' do
          expected_query = {
            'statementId': 'test',
            'agent': {
              'objectType': 'Agent',
              'name': user.full_name,
              'mbox': "mailto:#{user.email}",
            }.to_json,
          }
  
          expect(WebMock).to have_requested(:put, url)
            .with(body: post_body, query: expected_query).once
        end
      end

      context 'with a valid duration' do
        let(:query_parameters) {{ 'statementId': 'test' }}
        let(:post_body) {{
          'testParam1': 'test1',
          'testParam2': 'test2',
          'result': {
            'duration': 'PT0.6S',
          },
        }.to_json}
        let(:method) { 'PUT' }
  
        it 'passes the duration through unchanged' do
          expect(WebMock).to have_requested(:put, url)
            .with(body: post_body, query: query_parameters).once
        end
      end

    end # context 'xAPI statements endpoint'

    context 'xAPI state endpoint' do
      let(:endpoint) { LrsXapiProxy::XAPI_STATE_API_ENDPOINT }

      context 'PUT suspend_data' do
        let(:query_parameters) {{ 'stateId': 'suspend_data' }}
        let(:method) { 'PUT' }
        let(:post_body) { '{"v":1,"d":[123,34]]}' }

        it 'sets the request header' do
          expect(WebMock).to have_requested(:put, url).with(query: query_parameters, headers: {'Content-Type' => LrsXapiProxy::OCTET_STREAM_MIME_TYPE}).once
        end

        it 'passes the body' do
          expect(WebMock).to have_requested(:put, url).with(query: query_parameters, body: post_body).once
        end
      end

      context 'GET suspend_data' do
        let(:query_parameters) {{ 'stateId': 'suspend_data' }}
        let(:method) { 'GET' }
        let(:response_body) { '{"v":1,"d":[123,34]]}' }
  
        it 'returns the response' do
          expect(WebMock).to have_requested(:get, url).with(query: query_parameters).once
          expect(response.body).to eq(response_body)
        end

        it 'sets the response header' do
          expect(WebMock).to have_requested(:get, url).with(query: query_parameters).once
          expect(response.headers[:content_type]).to eq(LrsXapiProxy::OCTET_STREAM_MIME_TYPE)
        end
      end

      context 'PUT bookmark' do
        let(:query_parameters) {{ 'stateId': 'bookmark' }}
        let(:method) { 'PUT' }
        let(:post_body) { '#/lessons/xQvXXBKjohmGHnPUlyck9VqMlQ0hgcgy' }

        it 'sets the request header' do
          expect(WebMock).to have_requested(:put, url).with(query: query_parameters, headers: {'Content-Type' => LrsXapiProxy::OCTET_STREAM_MIME_TYPE}).once
        end

        it 'passes the body' do
          expect(WebMock).to have_requested(:put, url).with(query: query_parameters, body: post_body).once
        end
      end

      context 'GET bookmark' do
        let(:query_parameters) {{ 'stateId': 'bookmark' }}
        let(:method) { 'GET' }
        let(:response_body) { '#/lessons/xQvXXBKjohmGHnPUlyck9VqMlQ0hgcgy' }
  
        it 'returns the response' do
          expect(WebMock).to have_requested(:get, url).with(query: query_parameters).once
          expect(response.body).to eq(response_body)
        end

        it 'sets the response header' do
          expect(WebMock).to have_requested(:get, url).with(query: query_parameters).once
          expect(response.headers[:content_type]).to eq(LrsXapiProxy::OCTET_STREAM_MIME_TYPE)
        end
      end

      context 'PUT cumulative_time' do
        let(:query_parameters) {{ 'stateId': 'cumulative_time' }}
        let(:method) { 'PUT' }
        let(:post_body) { '3356598' }

        it 'sets the request header' do
          expect(WebMock).to have_requested(:put, url).with(query: query_parameters, headers: {'Content-Type' => LrsXapiProxy::OCTET_STREAM_MIME_TYPE}).once
        end


        it 'passes the body' do
          expect(WebMock).to have_requested(:put, url).with(query: query_parameters, body: post_body).once
        end
      end

      context 'GET cumulative_time' do
        let(:query_parameters) {{ 'stateId': 'cumulative_time' }}
        let(:method) { 'GET' }
        let(:response_body) { '3356598' }
  
        it 'returns the response' do
          expect(WebMock).to have_requested(:get, url).with(query: query_parameters).once
          expect(response.body).to eq(response_body)
        end

        it 'sets the response header' do
          expect(WebMock).to have_requested(:get, url).with(query: query_parameters).once
          expect(response.headers[:content_type]).to eq(LrsXapiProxy::OCTET_STREAM_MIME_TYPE)
        end
      end

    end # context 'xAPI state endpoint'

  end
end

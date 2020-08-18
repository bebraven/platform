require 'rails_helper'
require 'restclient_instrumentation'

RSpec.describe RestClientInstrumentation do

RestClient::Request.prepend(RestClientInstrumentation)

  let(:span) { instance_double(Honeycomb::Span) }
  let(:class_name) { 'Example' }
  let(:target_url) { 'https://fakeurl.com/some/path' }
  let(:fake_body) { '{"fake":"response"}' }
  let(:expected_headers) { {} }

  before(:each) do
    expect(Honeycomb).to receive(:start_span).and_yield(span)
    expect(span).to receive(:add_field).with('class_name', class_name).once # Example is the class one caller up. E.g. the `it` block.
    expect(span).to receive(:add_field).with('method', method).once
    expect(span).to receive(:add_field).with('url', target_url).once
    expect(span).to receive(:add_field).with('timestamp', anything).once
    expect(span).to receive(:add_field).with('headers', hash_including(expected_headers)).once
    expect(span).to receive(:add_field).with('status', status).once
    stub_request(method.to_sym, target_url).to_return(body: fake_body, status: status) 
  end

  context 'successful GET request' do
    let(:method) { 'get' }
    let(:status) { 200 }

    context 'without authorization header' do
      it 'returns the body' do
        response = RestClient.get(target_url)
        expect(response).to eq(fake_body)
      end
    end
  
    context 'with :authorization header => "Basic sometoken"' do
      let(:expected_headers) { {'Authorization' => '[REDACTED]' } }
      it 'redacts the header value' do
        response = RestClient.get(target_url, { :authorization => 'Basic fakeauthtoken' } )
        expect(response).to eq(fake_body)
      end
    end

    context 'with "Authorization: Bearer sometoken" header' do
      let(:expected_headers) { {'Authorization' => '[REDACTED]' } }
      it 'redacts the :authorization header' do
        response = RestClient.get(target_url, { 'Authorization' => 'Bearer fakeauthtoken' } )
        expect(response).to eq(fake_body)
      end
    end

  end

  context 'failed GET request' do
    let(:method) { 'get' }
    let(:status) { 401 }
    let(:fake_body) { '{"errors":{"type":"unauthorized","message":"Missing access token"}}' }
    let(:class_name) { 'RaiseError' }

    it 'adds error details to Honeycomb' do
      expect(span).to receive(:add_field).with('error', '401 Unauthorized')
      expect(span).to receive(:add_field).with('error_response', fake_body)
      expect { RestClient.get(target_url) }.to raise_error(RestClient::Exception)
    end
  end
end

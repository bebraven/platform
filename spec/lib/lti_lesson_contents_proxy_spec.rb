require 'rails_helper'

RSpec.describe LtiLessonContentsProxy do
  include Rack::Test::Methods # Allows us to use a dummy Rack::Request / Response framework

  before(:all) do
    @aws_bucket_url = "https://#{Rails.application.secrets.aws_files_bucket}.s3.amazonaws.com"
  end

  let(:dummy_host) { 'platform.host' }
  let(:dummy_path) { '/some/path' }
  let(:dummy_env) { { 'HTTP_HOST' => dummy_host, 'PATH_INFO' => dummy_path } }
  let(:dummy_body) { 'Hello world!' }
  let(:dummy_app) { proc{[200,dummy_env,[dummy_body]]} }
  #let(:stack) { LrsXapiProxy.new(app) }
  #let(:request) { Rack::MockRequest.new(stack) }

  # This "app" is required by Rack::Test::Methods
  def app
   LtiLessonContentsProxy.new(dummy_app, :backend => @aws_bucket_url)
  end

  context 'non-proxied request' do

    it 'ignores root path' do
      get('/')
      expect(WebMock).not_to have_requested(:any, @aws_bucket_url)
      expect(last_request.get_header('HTTP_HOST')).to eq(Rack::Test::DEFAULT_HOST)
    end

    it 'ignores SSO path' do
      get('/cas/login')
      expect(WebMock).not_to have_requested(:any, @aws_bucket_url)
      expect(last_request.get_header('HTTP_HOST')).to eq(Rack::Test::DEFAULT_HOST)
    end

  end

  context 'proxied request' do
    let(:fake_html) { '<html><head></head><body>Proxied Response</body></html>' }
    let(:aws_request_uri) { '/lessons/ytec17h3ckbr92vcf7nklxmat4tc/index.html?' \
                           'actor=%7B%22name%22%3A%22LESSON_CONTENTS_USERNAME_REPLACE%22%2C%20%22mbox%22%3A%5B%22mailto%3ALESSON_CONTENTS_PASSWORD_REPLACE%22%5D%7D'\
                           '&endpoint=https%3A%2F%2Fplatformweb%2Fdata%2FxAPI' 
                         }
    let(:original_full_path) { "#{LtiLessonContentsProxy::PROXIED_PATH}#{aws_request_uri}" }
    let(:proxied_request_url) { "#{@aws_bucket_url}#{aws_request_uri}" }

    before(:each) do
      stub_request(:get, proxied_request_url).to_return({:body => fake_html})
      get(original_full_path)
    end

    it 'hits the AWS S3 endpoint' do
      expect(WebMock).to have_requested(:get, proxied_request_url).once
      expect(last_response.body).to eq(fake_html)
    end

    it 'sets the host header to AWS' do
      expect(last_request.host).to eq(URI(@aws_bucket_url).host)
    end

  end
end 

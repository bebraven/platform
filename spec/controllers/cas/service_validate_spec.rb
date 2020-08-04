require "rails_helper"
require "capybara_helper"

include ERB::Util
include Rack::Utils

unless ENV['BZ_AUTH_SERVER'] # Only run these specs if on a server with local database authentication enabled

RSpec.describe CasController, type: :routing do
  describe "RubyCAS routing" do
    let!(:valid_user) { create(:registered_user) }
    let(:valid_user_creds) {{ email: valid_user.email, password: valid_user.password }}
  
    let(:return_service) { 'http://braven/' }
    let(:proxy_service) { 'http://bravenproxy/' }

    describe "/cas/serviceValidate" do
      let(:username) { valid_user_creds[:email] }
      let(:password) { valid_user_creds[:password] }

      context "without a login ticket" do 
        it "fails validate a service" do
          visit "/cas/serviceValidate"

          expect(page.body).to include("cas:authenticationFailure")
          expect(page.body).to include("INVALID_REQUEST")
          expect(page.body).to include("Ticket or service parameter was missing in the request.")
        end
      end

      context "with valid user" do
        before(:each) do
          VCR.use_cassette('sso_ticket_invalid', :match_requests_on => [:path]) do
            visit "/cas/login?service=#{url_encode(return_service)}"
            fill_and_submit_login(username, password)
          end
        end

        context "with a valid login ticket" do 
          before(:each) do
            @params = parse_query(current_url, "&?,")
          end
          it "logs in successfully and validates service" do
            visit "/cas/serviceValidate?ticket=#{@params['ticket']}&service=#{url_encode(return_service)}"
            expect(page.body).to include("cas:authenticationSuccess>")
            expect(page.body).to include(valid_user.email)
          end

          #it "logs in successfully and validates service with proxy url" do
          #  pending "Need to get proxy service set up"

          #  visit "/cas/serviceValidate?ticket=#{@params['ticket']}&service=#{url_encode(return_service)}&pgtUrl=#{proxy_service}"
          #  expect(page.body).to include("cas:authenticationSuccess>")
          #  expect(page.body).to include('platform_usr')
          #end

          it "fails validate a service because no service specified" do
            # Attempt to validate the service
            visit "/cas/serviceValidate?ticket=#{@params['ticket']}"
            expect(page.body).to include("cas:authenticationFailure")
            expect(page.body).to include("INVALID_REQUEST")
            expect(page.body).to include("Ticket or service parameter was missing in the request.")
          end

          it "fails validate a service because ticket is consumed" do
            # Validate service ticket
            visit "/cas/serviceValidate?ticket=#{@params["ticket"]}&service=#{return_service}"

            # Should be consumed
            visit "/cas/serviceValidate?ticket=#{@params["ticket"]}&service=#{return_service}"

            expect(page.body).to include("cas:authenticationFailure")
            expect(page.body).to include("INVALID_TICKET")
            expect(page.body).to include("as already been used up")
          end
        end

      end
    end
  end
end

end # unless ENV['BZ_AUTH_SERVER']

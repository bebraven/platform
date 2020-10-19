require "rails_helper"
require "capybara_helper"
require "json"

include ERB::Util
include Rack::Utils

unless ENV['BZ_AUTH_SERVER'] # Only run these specs if on a server with local database authentication enabled

RSpec.describe CasController, type: :routing do
  let!(:valid_user) { create(:registered_user) }
  let(:valid_user_creds) {{ email: valid_user.email, password: valid_user.password }}
  let(:return_service) { 'http://braven/cas/login' }

  describe "RubyCAS routing" do
    describe "/cas/proxyValidate" do
      context "with a valid user" do
        let(:username) { valid_user_creds[:email] }
        let(:password) { valid_user_creds[:password] }

        before(:each) do
          VCR.use_cassette('sso_ticket_invalid', :match_requests_on => [:path]) do
            visit "/cas/login?service=#{url_encode(return_service)}"
            fill_and_submit_login(username, password)
          end
        end
        it "contains a ticket" do
          expect(current_url).to include("ticket")
        end
        context "with valid proxy ticket" do
          before(:each) do
            VCR.use_cassette('sso_ticket_invalid', :match_requests_on => [:path]) do
              @params = parse_query(current_url, "&?,")
              visit "/cas/proxyValidate?ticket=#{@params["ticket"]}&service=#{return_service}"
            end
          end
          it "validates proxy ticket" do
            # Capybara can't handle XMLs properly, use the result string
            expect(page.body).to include("authenticationSuccess")
            expect(page.body).to include(valid_user_creds[:email])
          end
        end
      end

      context "without specifying a proxy ticket" do
        it "fails validate proxy ticket" do
          # Attempt to validate the ticket
          visit "/cas/proxyValidate"

          expect(page.body).to include("authenticationFailure")
          expect(page.body).to include("INVALID_REQUEST")
          expect(page.body).to include("Ticket or service parameter was missing in the request.")
        end
      end
    end
  end
end

end # unless ENV['BZ_AUTH_SERVER']

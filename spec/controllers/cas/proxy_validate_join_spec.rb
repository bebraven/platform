require "rails_helper"
require "capybara_helper"
require "platform_helper"
require "json"

include ERB::Util
include Rack::Utils

if ENV['BZ_AUTH_SERVER'] # Only run these specs if on a server with Join authentication enabled

RSpec.describe CasController, type: :routing do
  let(:valid_user) {{ email: 'platform_user', password: 'rspec_test' }}
  let(:return_service) { 'http://braven/' }
  let(:host_servers) {{ join_server: "#{ENV['VCR_JOIN_SERVER']}", canvas_server: "#{ENV['VCR_CANVAS_SERVER']}" }}

  describe "RubyCAS routing" do
    describe "/cas/proxyValidate" do
      context "with a valid user" do
        let(:join_cassette) { "join_auth_valid" }
        let(:username) { valid_user[:email] }
        let(:password) { valid_user[:password] }

        before(:each) do 
          visit "/cas/login?service=#{url_encode(return_service)}"
          VCR.use_cassette(join_cassette, :erb => host_servers) do
            fill_and_submit_login(username, password)
          end
        end
        it "contains a ticket" do
          expect(current_url).to include("ticket")
        end 
        context "with valid proxy ticket" do
          before(:each) do
            @params = parse_query(current_url, "&?,")
            visit "/cas/proxyValidate?ticket=#{@params["ticket"]}&service=#{return_service}"      
          end
          it "validates proxy ticket" do
            # Capybara can't handle XMLs properly, use the result string 
            expect(page.body).to include("authenticationSuccess")
            expect(page.body).to include(valid_user[:email])
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

end # if ENV['BZ_AUTH_SERVER']

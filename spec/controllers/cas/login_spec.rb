require "rails_helper"
require "capybara_helper"

include ERB::Util
include Rack::Utils

unless ENV['BZ_AUTH_SERVER'] # Only run these specs if on a server with local database authentication enabled

RSpec.describe CasController, type: :routing do
  let!(:valid_user) { create(:registered_user) }
  let(:valid_user_creds) {{ email: valid_user.email, password: valid_user.password }}
  let(:invalid_user_creds) {{ email: 'bad_user', password: 'bad_pass' }}

  describe "RubyCAS Controller" do
    describe "/cas/login without service url" do
      before(:each) do 
        visit "/cas/login"
        fill_and_submit_login(username, password)
      end
      context "when username and password are valid" do
        let(:username) { valid_user_creds[:email] }
        let(:password) { valid_user_creds[:password] }
        
        it "logs in successfully" do
          # Ensure that the login was successful
          expect(page).to have_content("You have successfully logged in")
        end
      end
      context "when username and password are invalid" do
        let(:username) { invalid_user_creds[:email] }
        let(:password) { invalid_user_creds[:password] }

        it "fails to log in" do
          # Ensure that the login was failed
          expect(page).to have_content("Incorrect username or password")
        end
      end
    end

    describe "/cas/login with service url" do
      let(:return_service) { 'http://braven/cas/login' }
      before(:each) do 
        VCR.use_cassette("sso_ticket_invalid", :match_requests_on => [:path]) do
          visit "/cas/login?service=#{url_encode(return_service)}"
          fill_and_submit_login(username, password)
        end
      end

      context "when username and password are valid" do
        let(:username) { valid_user_creds[:email] }
        let(:password) { valid_user_creds[:password] }
        
        it "logs in successfully" do
          # Ensure that the login was successful
          expect(current_url).to include(return_service)
          expect(current_url).to include("ticket")
        end

        it "validates existing tickets" do
          @params = parse_query(current_url, "&?,")
          expect(@params).to include("ticket")
        end

        it "generates new ticket when revisiting login page" do
          VCR.use_cassette("sso_ticket_invalid", :match_requests_on => [:path]) do
            # Get current ticket to check against next generated ticket
            @params = parse_query(current_url, "&?,")
            visit "/cas/login?service=#{url_encode(return_service)}"

            # New ticket should be generated
            expect(current_url).not_to include(@params["ticket"])
          end
        end
      end
    end
    describe "/cas/login using onlyLoginForm parameter" do
      before(:each) do 
        visit "/cas/login?onlyLoginForm=true"
        fill_and_submit_login(username, password)
      end

      context "when username and password are valid" do
        let(:username) { valid_user_creds[:email] }
        let(:password) { valid_user_creds[:password] }

        it "logs in successfully" do
          # Ensure that the login was successful
          expect(page).to have_content("You have successfully logged in")
        end
      end
    end
  end
end

end # if  ENV['BZ_AUTH_SERVER']

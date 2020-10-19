require "rails_helper"
require "capybara_helper"

include ERB::Util
include Rack::Utils

if ENV['BZ_AUTH_SERVER'] # Only run these specs if on a server with Join authentication enabled

RSpec.describe CasController, type: :routing do
  let(:valid_user) {{ email: 'platform_user', password: 'rspec_test' }}
  let(:invalid_user) {{ email: 'bad_user', password: 'bad_pass' }}
  let(:host_servers) {{ join_server: "#{ENV['VCR_JOIN_SERVER']}", canvas_server: "#{ENV['VCR_CANVAS_SERVER']}" }}

  describe "RubyCAS Controller" do
    describe "/cas/login without service url" do
      before(:each) do 
        visit "/cas/login"
        VCR.use_cassette(join_cassette, :erb => host_servers) do
          fill_and_submit_login(username, password)
        end
      end
      context "when username and password are valid" do
        let(:join_cassette) { "join_auth_valid" }
        let(:username) { valid_user[:email] }
        let(:password) { valid_user[:password] }
        
        it "logs in successfully" do
          # Ensure that the login was successful
          expect(page).to have_content("You have successfully logged in")
        end
      end
      context "when username and password are invalid" do
        let(:join_cassette) { "join_auth_invalid" }
        let(:username) { invalid_user[:email] }
        let(:password) { invalid_user[:password] }

        it "fails to log in" do
          # Ensure that the login was failed
          expect(page).to have_content("Incorrect username or password")
        end
      end
    end

    describe "/cas/login without service url" do
      let(:return_service) { 'http://braven/' }
      before(:each) do 
        visit "/cas/login?service=#{url_encode(return_service)}"
        VCR.use_cassette(join_cassette, :erb => host_servers) do
          fill_and_submit_login(username, password)
        end
      end

      context "when username and password are valid" do
        let(:join_cassette) { "join_auth_valid" }
        let(:username) { valid_user[:email] }
        let(:password) { valid_user[:password] }
        
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
          # Get current ticket to check against next generated ticket
          @params = parse_query(current_url, "&?,")
          visit "/cas/login?service=#{url_encode(return_service)}"

          # New ticket should be generated
          expect(current_url).not_to include(@params["ticket"])
        end
      end
    end
    describe "/cas/login using onlyLoginForm parameter" do
      before(:each) do 
        visit "/cas/login?onlyLoginForm=true"
        VCR.use_cassette(join_cassette, :erb => host_servers) do
          fill_and_submit_login(username, password)
        end
      end

      context "when username and password are valid" do
        let(:join_cassette) { "join_auth_valid" }
        let(:username) { valid_user[:email] }
        let(:password) { valid_user[:password] }

        it "logs in successfully" do
          # Ensure that the login was successful
          expect(page).to have_content("You have successfully logged in")
        end
      end
    end
  end
end

end # end if ENV['BZ_AUTH_SERVER']

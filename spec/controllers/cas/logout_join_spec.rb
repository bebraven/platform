require "rails_helper"
require "capybara_helper"
require "platform_helper"

include ERB::Util
include Rack::Utils

if ENV['BZ_AUTH_SERVER'] # Only run these specs if on a server with Join authentication enabled

RSpec.describe CasController, type: :routing do
  let(:valid_user) {{ email: 'platform_user', password: 'rspec_test' }}
  let(:host_servers) {{ join_server: "#{ENV['VCR_JOIN_SERVER']}", canvas_server: "#{ENV['VCR_CANVAS_SERVER']}" }}

  describe "RubyCAS routing" do
    describe "/cas/logout " do
      let(:join_cassette) { "join_auth_valid" }
      let(:username) { valid_user[:email] }
      let(:password) { valid_user[:password] }

      context "without service url" do
        before(:each) do 
          visit "/cas/login"
          VCR.use_cassette(join_cassette, :erb => host_servers) do
            fill_and_submit_login(username, password)
          end
        end
        it "logout successfully" do
          # Ensure that the login was successful
          visit "/cas/logout"
          expect(page).to have_content('You have successfully logged out')
        end
      end

      context "with service url" do
        let(:return_service) { 'http://braven/' }
        before(:each) do 
          visit "/cas/login?service=#{url_encode(return_service)}"
          VCR.use_cassette(join_cassette, :erb => host_servers) do
            fill_and_submit_login(username, password)
          end
        end
        it "logout successfully" do
          visit "/cas/logout"
          expect(page).to have_content('You have successfully logged out')
        end
      end
    end
  end
end

end # if ENV['BZ_AUTH_SERVER']

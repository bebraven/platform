require 'rails_helper'
require 'capybara_helper'
require 'platform_helper'

require 'linked_in_api'

RSpec.feature 'Authorize LinkedIn access to user data', :type => :feature do
  let(:user) { create :linked_in_user, admin: true }

  describe "visit the signin page", js: true do
    before(:each) do
      VCR.configure do |c|
        c.ignore_localhost = true
        c.ignore_hosts Capybara.server_host
      end

      visit path
      fill_and_submit_login(user.email, user.password)
    end

    context "signin" do
      let(:path) { linked_in_login_path }

      it "renders the LinkedIn sign-in link", js: true do
        expect(current_url).to include(linked_in_login_path)
        expect(page).to have_selector('#linked-in-login')
      end

      it "sign-in link opens a new window", js: true, ci_exclude: true do
        # Click link
        popup = window_opened_by { find('#linked-in-login').click }
 
        # Check pop-up
        within_window popup do
          expect(current_url).to include('https://www.linkedin.com/')

          # Note: this page title is specified by LinkedIn, if it changes
          # this test will fail until we update the string.
          # We only check that the title ends to "| LinkedIn" because it can
          # vary depending on whether the test runs on an endpoint that's
          # whitelisted by Braven's LinkedIn app. 
          expect(page.title).to match(/| LinkedIn$/)
        end
      end
    end

    context "launch" do
      let(:path) { linked_in_auth_path }

      it "redirects to the LinkedIn", js: true, ci_exclude: true do
          expect(current_url).to include('https://www.linkedin.com/')
          expect(page.title).to match(/| LinkedIn$/)
      end
    end
  end
end

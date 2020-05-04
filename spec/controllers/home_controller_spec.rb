require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  render_views
  let(:user) { create :admin_user }

  before do
    sign_in user
  end

  describe "GET #welcome" do
    it "returns http success" do
      get :welcome
      expect(response).to have_http_status(:success)
    end
  end

end

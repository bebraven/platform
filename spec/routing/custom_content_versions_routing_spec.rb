require "rails_helper"

RSpec.describe CustomContentVersionsController, type: :routing do
  let(:custom_content) { create(:custom_content) }
  
  describe "routing" do
    it "routes to #index" do
      expect(:get => "/custom_contents/#{custom_content.id}/versions").to route_to("custom_content_versions#index",
          :custom_content_id => custom_content.id.to_s)
    end

    it "routes to #show" do
      expect(:get => "/custom_contents/#{custom_content.id}/versions/1").to route_to("custom_content_versions#show",
          :id => "1", :custom_content_id => custom_content.id.to_s)
    end
  end
end

# This tests that public-facing course_contents/ paths route correctly after 
# the CourseContentsController -> CustomContentsController migration
require "rails_helper"

RSpec.describe CustomContentsController, type: :routing do
  let(:custom_content) { create(:custom_content) }

  describe "routing" do
    it "routes to #show" do
      expect(:get => "/course_contents/1").to route_to("custom_contents#show", :id => "1")
    end

    it "routes to #index" do
      expect(:get => "/course_contents/#{custom_content.id}/versions").to route_to("custom_content_versions#index",
          :custom_content_id => custom_content.id.to_s)
    end

    it "routes to #show" do
      expect(:get => "/course_contents/#{custom_content.id}/versions/1").to route_to("custom_content_versions#show",
          :id => "1", :custom_content_id => custom_content.id.to_s)
    end
  end
end

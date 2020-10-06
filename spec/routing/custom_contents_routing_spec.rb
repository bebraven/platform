require "rails_helper"

RSpec.describe CustomContentsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(:get => "/custom_contents").to route_to("custom_contents#index")
    end

    it "routes to #new" do
      expect(:get => "/custom_contents/new").to route_to("custom_contents#new")
    end

    it "routes to #show" do
      expect(:get => "/custom_contents/1").to route_to("custom_contents#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/custom_contents/1/edit").to route_to("custom_contents#edit", :id => "1")
    end


    it "routes to #create" do
      expect(:post => "/custom_contents").to route_to("custom_contents#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/custom_contents/1").to route_to("custom_contents#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/custom_contents/1").to route_to("custom_contents#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/custom_contents/1").to route_to("custom_contents#destroy", :id => "1")
    end
  end
end

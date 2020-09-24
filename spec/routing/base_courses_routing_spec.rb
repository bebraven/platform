require "rails_helper"

RSpec.describe BaseCoursesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(:get => "/course_management").to route_to("base_courses#index")
    end

    # Courses
    it "routes to #new with type Course" do
      expect(:get => "/courses/new").to route_to("base_courses#new", :type => "Course")
    end

    it "routes to #edit with type Course" do
      expect(:get => "/courses/1/edit").to route_to("base_courses#edit", :id => "1", :type => "Course")
    end

    it "routes to #create with type Course" do
      expect(:post => "/courses").to route_to("base_courses#create", :type => "Course")
    end

    it "routes to #update via PUT with type Course" do
      expect(:put => "/courses/1").to route_to("base_courses#update", :id => "1", :type => "Course")
    end

    it "routes to #update via PATCH with type Course" do
      expect(:patch => "/courses/1").to route_to("base_courses#update", :id => "1", :type => "Course")
    end

    it "routes to #destroy with type Course" do
      expect(:delete => "/courses/1").to route_to("base_courses#destroy", :id => "1", :type => "Course")
    end

    # CourseTemplates
    it "routes to #new with type CourseTemplate" do
      expect(:get => "/course_templates/new").to route_to("base_courses#new", :type => "CourseTemplate")
    end

    it "routes to #edit with type CourseTemplate" do
      expect(:get => "/course_templates/1/edit").to route_to("base_courses#edit", :id => "1", :type => "CourseTemplate")
    end

    it "routes to #create with type CourseTemplate" do
      expect(:post => "/course_templates").to route_to("base_courses#create", :type => "CourseTemplate")
    end

    it "routes to #update via PUT with type CourseTemplate" do
      expect(:put => "/course_templates/1").to route_to("base_courses#update", :id => "1", :type => "CourseTemplate")
    end

    it "routes to #update via PATCH with type CourseTemplate" do
      expect(:patch => "/course_templates/1").to route_to("base_courses#update", :id => "1", :type => "CourseTemplate")
    end

    it "routes to #destroy with type CourseTemplate" do
      expect(:delete => "/course_templates/1").to route_to("base_courses#destroy", :id => "1", :type => "CourseTemplate")
    end
  end
end

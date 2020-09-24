class GradeCategoriesController < ApplicationController
  include DryCrud::Controllers::Nestable

  nested_resource_of BaseCourse

  # GET /grade_categories
  # GET /grade_categories.json
  def index
  end

  # GET /grade_categories/1
  # GET /grade_categories/1.json
  def show
  end

end

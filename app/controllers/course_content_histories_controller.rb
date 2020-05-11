class CourseContentHistoriesController < ApplicationController
  layout 'content_editor'
  before_action :set_course_content, only: [:index, :show]

  include DryCrud::Controllers::Nestable

  nested_resource_of CourseContent

  # GET /course_contents/:id/versions
  # GET /course_contents/:id/versions.json
  def index
  end

  # GET /course_contents/:id/versions/1
  # GET /course_contents/:id/versions/1.json
  def show
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_course_content
      @course_content = CourseContent.find(params[:course_content_id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def course_content_history_params
      params.require(:course_content_history).permit(:course_content_id, :title, :body, :user)
    end
end

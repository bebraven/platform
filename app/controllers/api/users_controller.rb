# frozen_string_literal: true

module Api
  class UsersController < ApplicationController
    include DryCrud::Controllers::Nestable
    nested_resource_of Section

    # GET sections/{section_id}/users
    def index
      authorize @section.course
      # FIXME: Check for params[:section_roles]
      render json: @section.students.map { |student| { id: student.id, name: student.full_name } }
    end
  end
end

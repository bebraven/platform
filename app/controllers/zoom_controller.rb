# frozen_string_literal: true

# Zoom controller
class ZoomController < ApplicationController
  layout 'admin'

  def home
    authorize :application, :index?
  end

end

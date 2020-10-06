class HomeController < ApplicationController
  layout 'admin'

  def welcome
    authorize :application, :index?
  end
end

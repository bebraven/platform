class NetworkController < ApplicationController
  layout 'network'
  before_action :authorize_network
  skip_before_action :authenticate_user!, only: [:join]
  
  def connect
    @active_requests = []
  end

  def join
    @champion = Champion.new
    @industries = list_names_in_table(Industry)
    @fields = list_names_in_table(Field)
  end

  private

  def authorize_network
    authorize :network
  end

  def list_names_in_table(model)
    model.all.order(:name).pluck(:name)
  end
end

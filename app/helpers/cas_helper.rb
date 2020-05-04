module CasHelper

  # Allows us to use Devise view stuff in the CasController.
  # See: https://stackoverflow.com/questions/4081744/devise-form-within-a-different-controller

  def resource_name
    @resource_name ||= :user
  end
  
  def resource
    @resource ||= resource_name.to_s.classify.constantize.new
  end
  
  def devise_mapping
    @devise_mapping ||= Devise.mappings[resource_name]
  end

end

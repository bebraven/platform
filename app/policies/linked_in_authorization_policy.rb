class LinkedInAuthorizationPolicy < ApplicationPolicy

  def login?
    !!user
  end

  def launch?
    login?
  end

  def oauth_redirect?
    login?
  end

end

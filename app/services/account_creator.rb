# frozen_string_literal: true

class AccountCreator # rubocop:disable Style/Documentation
  def initialize(sign_up_params:, for_nlu: false)
    @sign_up_params = sign_up_params
    @salesforce_contact = nil
    @for_nlu = for_nlu
  end

  def run
    # Create the platform user synchronously, so we're guaranteed to have it
    # during Canvas user setup.
    create_platform_user!
    setup_portal_user!
  end

  private

  def salesforce_contact_id
    @sign_up_params['salesforce_id']
  end

  def setup_portal_user!
    SetupPortalAccountJob.perform_later(salesforce_contact.id)
  end

  def create_platform_user!
    user = User.new(platform_user_params)
    user.skip_confirmation_notification!
    user.save!
    user
  end

  def platform_user_params
    password_params
      .merge({
               email: salesforce_contact.email,
               first_name: salesforce_contact.first_name,
               last_name: salesforce_contact.last_name,
               salesforce_id: salesforce_contact.id
             })
  end

  def password_params
    if @for_nlu
      # NLU students don't need a password on platform. They use their SSO to
      # log into portal not the platform. This is why we just create a random
      # password on platform just to have user on platform but not for log in
      password = Devise.friendly_token[0, 20]
      { password: password, password_confirmation: password }
    else
      {
        password: @sign_up_params['password'],
        password_confirmation: @sign_up_params['password_confirmation']
      }
    end
  end

  def salesforce_contact
    @salesforce_contact ||= sf_client.find_contact(id: salesforce_contact_id)
  end

  def sf_client
    SalesforceAPI.client
  end
end

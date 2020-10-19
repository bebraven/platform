# frozen_string_literal: true

class AccountCreator
  def initialize(sign_up_params:)
    @salesforce_contact_id = sign_up_params['salesforce_id']
    @password_params = {
      'password' => sign_up_params['password'],
      'password_confirmation' => sign_up_params['password_confirmation']
    }
    @salesforce_contact = nil
  end

  def run
    # Create the platform user synchronously, so we're guaranteed to have it
    # during Canvas user setup.
    create_platform_user!
    setup_portal_user!
  end

  private

  attr_reader :salesforce_contact_id

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
    @password_params
      .merge({
               email: salesforce_contact.email,
               first_name: salesforce_contact.first_name,
               last_name: salesforce_contact.last_name,
               salesforce_id: salesforce_contact.id
             })
  end

  def salesforce_contact
    @salesforce_contact ||= sf_client.find_contact(id: salesforce_contact_id)
  end

  def sf_client
    SalesforceAPI.client
  end
end

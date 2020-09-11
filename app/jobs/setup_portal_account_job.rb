# frozen_string_literal: true

class SetupPortalAccountJob < ActiveJob::Base
  queue_as :default

  def perform(salesforce_contact_id)
    SetupPortalAccount.new(salesforce_contact_id: salesforce_contact_id).run
  end
end

# frozen_string_literal: true

class ReconcileUserEmail
  def initialize(salesforce_participant:, portal_user:)
    @sf_participant = salesforce_participant
    @portal_user = portal_user
  end

  def run
    # NOOP for now
    # We haven't figured out how to reconcile this and what system we need to
    # update
  end
end

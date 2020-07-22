# frozen_string_literal: true

# Salesforce controller
class SalesforceController < ApplicationController
  def sync_to_lms
    # TODO: this is a complete hack just to get a prototype going. When we implement this for real,
    # it should be an API that Salesforce can call into (and we need some sort of auth / protection).
    #
    # Notes: if this fails, how to report back to the user that forced it from Salesforce?
    # Say it takes a minute or two to run, can we have Salesforce wait for the response?
    # If not, queue this up on the background and have a page listing recent runs and their status?
    # Send an email?
    program_id = params[:program_id]
    email = params[:email]
    if program_id && email
      SalesforceProgramToLmsSyncJob.perform_later(program_id, email)
      @user_notification = "Sync To LMS has been submitted for program #{program_id}, #{email} will be notified"
    else
      @user_notification = 'Please enter the Program ID to sync below and hit Enter'
    end
  end
end

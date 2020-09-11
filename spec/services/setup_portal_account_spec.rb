# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetupPortalAccount do
  describe '#run' do
    let(:sf_client) { double('SalesforceAPI', find_participant: SalesforceAPI::SFParticipant.new, find_program: SalesforceAPI::SFProgram.new, update_contact: nil) }
    let(:canvas_client) { double('CanvasAPI', find_user_by: CanvasAPI::LMSUser.new, create_account: CanvasAPI::LMSUser.new) }
    let(:platform_user) { double('User', update!: nil, send_confirmation_instructions: nil) }
    let(:enrollment_process) { double('SyncPortalEnrollmentForAccount', run: nil) }

    before(:each) do
      allow(SalesforceAPI).to receive(:client).and_return(sf_client)
      allow(CanvasAPI).to receive(:client).and_return(canvas_client)
      allow(SyncPortalEnrollmentForAccount).to receive(:new).and_return(enrollment_process)
      allow(User).to receive(:find_by!).and_return(platform_user)
    end

    it 'creates a canvas user when it does not exist' do
      enrolled_participant = SalesforceAPI::SFParticipant.new(nil, nil, nil, nil, nil, nil, SalesforceAPI::ENROLLED)
      allow(sf_client).to receive(:find_participant).and_return(enrolled_participant)
      allow(canvas_client).to receive(:find_user_by).and_return(nil)

      SetupPortalAccount.new(salesforce_contact_id: nil).run

      expect(canvas_client).to have_received(:create_account)
    end

    it 'raises an error if user is not enrolled and the user does not exist' do
      dropped_participant = SalesforceAPI::SFParticipant.new(nil, nil, nil, nil, nil, nil, SalesforceAPI::DROPPED)
      allow(sf_client).to receive(:find_participant).and_return(dropped_participant)
      allow(canvas_client).to receive(:find_user_by).and_return(nil)

      expect { SetupPortalAccount.new(salesforce_contact_id: nil).run }.to raise_error(SetupPortalAccount::UserNotEnrolledOnSFError)
    end

    it 'does not create a user if it exists' do
      SetupPortalAccount.new(salesforce_contact_id: nil).run

      expect(canvas_client).not_to have_received(:create_account)
    end

    it 'starts the portal enrollment process' do
      SetupPortalAccount.new(salesforce_contact_id: nil).run

      expect(enrollment_process).to have_received(:run)
    end

    it 'updates portal references on platform' do
      SetupPortalAccount.new(salesforce_contact_id: nil).run

      expect(platform_user).to have_received(:update!)
    end

    it 'updates portal references on salesforce' do
      SetupPortalAccount.new(salesforce_contact_id: nil).run

      expect(sf_client).to have_received(:update_contact)
    end

    it 'sends confirmation instructions to user' do
      SetupPortalAccount.new(salesforce_contact_id: nil).run

      expect(platform_user).to have_received(:send_confirmation_instructions)
    end
  end
end

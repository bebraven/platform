# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetupPortalAccount do
  describe '#run' do
    let(:sf_client) { instance_double('SalesforceAPI', find_participant: SalesforceAPI::SFParticipant.new, find_program: SalesforceAPI::SFProgram.new, update_contact: nil) }
    let(:canvas_client) { instance_double('CanvasAPI', find_user_by: CanvasAPI::LMSUser.new, create_account: CanvasAPI::LMSUser.new) }
    let(:platform_user) { instance_double('User', update!: nil, send_confirmation_instructions: nil, email: nil, first_name: nil, last_name: nil) }
    let(:enrollment_process) { instance_double('SyncPortalEnrollmentForAccount', run: nil) }

    let(:join_api_client) { instance_double('JoinAPI', find_user_by: JoinAPI::JoinUser.new, create_user: JoinAPI::JoinUser.new) }

    before do
      allow(SalesforceAPI).to receive(:client).and_return(sf_client)
      allow(CanvasAPI).to receive(:client).and_return(canvas_client)
      allow(SyncPortalEnrollmentForAccount).to receive(:new).and_return(enrollment_process)
      allow(User).to receive(:find_by!).and_return(platform_user)
      allow(JoinAPI).to receive(:client).and_return(join_api_client)
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

    it 'does not do join api stuff if no config var set' do
      ENV['CREATE_JOIN_USER_ON_SIGN_UP'] = nil
      SetupPortalAccount.new(salesforce_contact_id: nil).run

      expect(join_api_client).not_to have_received(:find_user_by)
    end


    it 'finds a join user if the user already exist' do
      ENV['CREATE_JOIN_USER_ON_SIGN_UP'] = 'foobar'
      SetupPortalAccount.new(salesforce_contact_id: nil).run

      expect(join_api_client).to have_received(:find_user_by)
    end

    it 'create a new join user if the user does not exist' do
      ENV['CREATE_JOIN_USER_ON_SIGN_UP'] = 'foobar'
      allow(join_api_client).to receive(:find_user_by).and_return(nil)

      SetupPortalAccount.new(salesforce_contact_id: nil).run

      expect(join_api_client).to have_received(:create_user)
    end

    it 'starts the portal enrollment process' do
      SetupPortalAccount.new(salesforce_contact_id: nil).run

      expect(enrollment_process).to have_received(:run)
    end

    it 'updates portal references on platform' do
      ENV['CREATE_JOIN_USER_ON_SIGN_UP'] = 'foobar'
      SetupPortalAccount.new(salesforce_contact_id: nil).run

      expect(platform_user).to have_received(:update!).twice
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

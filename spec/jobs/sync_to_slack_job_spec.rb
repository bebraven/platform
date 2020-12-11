# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SyncToSlackJob, type: :job do
  describe '#perform' do
    let(:sf_to_slack) { double('SyncSlackForProgram', run: nil) }
    let(:delivery) { double('DummyDeliverer', deliver_now: nil) }
    let(:mailer) { double('DummyMailerInstance', success_email: delivery, failure_email: delivery) }

    before(:each) do
      allow(SyncSlackForProgram).to receive(:new).and_return(sf_to_slack)
      allow(BackgroundSyncJobMailer).to receive(:with).and_return(mailer)
    end 

    let(:program_id) {'some_fake_id'}
    let(:email) {'example@example.com'}

    context 'if args are valid' do
      it 'syncs new program to slack' do
        SyncToSlackJob.perform_now(program_id, email)
        expect(sf_to_slack).to have_received(:run)
      end 

      it 'sends success email if successful' do
        SyncToSlackJob.perform_now(program_id, email)
        expect(mailer).to have_received(:success_email)
      end 
    end 

    context 'if args are invalid', :focus => true  do;
      it 'sends failure mail' do 
        allow(sf_to_slack).to receive(:run).and_raise('uh oh')
        SyncToSlackJob.perform_now(program_id, email)

        expect{ SyncToSlackJob.perform_now(program_id, email) }.to raise_error
        expect(mailer).to have_received(:failure_email)
      end 
    end 

  end 
end 
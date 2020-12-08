# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SyncToSlackJob, type: :job do
    describe '#perform' do
      let(:program_slack_cohorts) { double('SyncSlackForProgram', run: nil) }
      let(:delivery) { double('DummyDeliverer', deliver_now: nil) }
      let(:mailer) { double('DummyMailerInstance', success_email: delivery, failure_email: delivery) }
  
      before(:each) do
        allow(SyncSlackForProgram).to receive(:new).and_return(program_slack_cohorts)
        allow(BackgroundSyncJobMailer).to receive(:with).and_return(mailer)
      end
  
      it 'starts the sync process for a program id' do
        program_id = 'some_fake_id'
        email = 'example@example.com'
        SyncToSlackJob.perform_now(program_id, email)
  
        expect(program_slack_cohorts).to have_received(:run)
      end
      
      it 'sends success mail if successful' do
        program_id = 'some_fake_id'
        email = 'example@example.com'
        SyncToSlackJob.perform_now(program_id, email)
  
        expect(mailer).to have_received(:success_email)
      end
    end
  end


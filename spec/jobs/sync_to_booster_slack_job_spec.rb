# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SyncToBoosterSlackJob, type: :job do
  describe '#perform' do
    let(:email_list) { double('SyncBoosterSlackForEmails', run: nil) } 
    let(:mail_status) { double('MailStatusInstance', success_email: delivery, failure_email: delivery) }
    let(:delivery) { double('DeliverNowInstance', deliver_now: nil)}

    before(:each) do
      allow(SyncBoosterSlackForEmails).to receive(:new).and_return(email_list)
      allow(BackgroundSyncJobMailer).to receive(:with).and_return(mail_status)
    end 

    let(:emails) {'arbitrary list of emails'}
    let(:email) {'some email address'}

    context 'when args are valid' do
      it 'starts to sync emails to booster slack' do
        SyncToBoosterSlackJob.perform_now(emails,email)        
        expect(email_list).to have_received(:run)
      end 

      it 'sends success email if emails sync' do         
        SyncToBoosterSlackJob.perform_now(emails, email)
        expect(mail_status).to have_received(:success_email)
      end 
    end 

    context 'when args are invalid || .run fails' do
      it 'sends failure email', :focus => true do; 
        allow(email_list).to receive(:run).and_raise(RuntimeError)
        expect{ SyncToBoosterSlackJob.perform_now(emails, email) }.to raise_exception
        expect(mail_status).to have_received(:failure_email)
      end        
    end 

  end
end 


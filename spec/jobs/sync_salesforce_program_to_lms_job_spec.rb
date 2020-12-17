# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SyncSalesforceProgramToLmsJob, type: :job do
  describe '#perform' do
    let(:program_portal_enrollments) { double('SyncPortalEnrollmentsForProgram', run: nil) }
    let(:delivery) { double('DummyDeliverer', deliver_now: nil) }
    let(:mailer) { double('DummyMailerInstance', success_email: delivery, failure_email: delivery) }

    before(:each) do
      allow(SyncPortalEnrollmentsForProgram).to receive(:new).and_return(program_portal_enrollments)
      allow(BackgroundSyncJobMailer).to receive(:with).and_return(mailer)
    end

    let(:program_id) {'some_fake_id'}
    let(:email) {'some email address'}

    it 'starts the sync process for a program id' do
      SyncSalesforceProgramToLmsJob.perform_now(program_id, email)
      expect(program_portal_enrollments).to have_received(:run)
    end

    it 'sends success mail if successful', :focus => true do;
      SyncSalesforceProgramToLmsJob.perform_now(program_id, email)
      expect(mailer).to have_received(:success_email)
    end

    it 'sends failure mail if something bad happens' do
      allow(program_portal_enrollments).to receive(:run).and_raise(RuntimeError) 
      expect{ SyncSalesforceProgramToLmsJob.perform_now(program_id, email) }.to raise_exception
      expect(mailer).to have_received(:failure_email)
    end
  end
end

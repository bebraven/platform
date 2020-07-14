# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SalesforceProgramToLmsSyncJob, type: :job do
  describe '#perform' do
    let(:sync_to_lms) { double('SyncToLMS', for_program: nil) }
    let(:delivery) { double('DummyDeliverer', deliver_now: nil) }
    let(:mailer) { double('DummyMailerInstance', success_email: delivery, failure_email: delivery) }

    before(:each) do
      allow(SyncToLMS).to receive(:new).and_return(sync_to_lms)
      allow(SalesforceToLmsSyncMailer).to receive(:with).and_return(mailer)
    end

    it 'starts the sync process for a program id' do
      program_id = 'some_fake_id'
      email = 'example@example.com'
      SalesforceProgramToLmsSyncJob.perform_now(program_id, email)

      expect(sync_to_lms).to have_received(:for_program).with(program_id)
    end

    it 'sends success mail if successful' do
      program_id = 'some_fake_id'
      email = 'example@example.com'
      SalesforceProgramToLmsSyncJob.perform_now(program_id, email)

      expect(mailer).to have_received(:success_email)
    end

    it 'sends failure mail if something bad happens' do
      allow(sync_to_lms).to receive(:for_program).and_raise('something bad')
      program_id = 'some_fake_id'
      email = 'example@example.com'
      SalesforceProgramToLmsSyncJob.perform_now(program_id, email)

      expect(mailer).to have_received(:failure_email)
    end
  end
end

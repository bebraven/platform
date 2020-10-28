# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LaunchProgramJob, type: :job do
  describe '#perform' do
    let(:launch_program) { double(LaunchProgram, run: nil) }
    let(:delivery) { double('DummyDeliverer', deliver_now: nil) }
    let(:mailer) { double('DummyMailerInstance', success_email: delivery, failure_email: delivery) }
    let(:salesforce_program_id) { 'TestSalesforceProgramId' }
    let(:notification_email) { 'fake_notify@email.com' }
    let(:fellow_course_template_id) { '123123' }
    let(:fellow_course_name) { 'Test Fellow Course Name1' }
    let(:lc_course_template_id) { '423423' }
    let(:lc_course_name) { 'Test LC Course Name1' }

    before(:each) do
      allow(LaunchProgram).to receive(:new).and_return(launch_program)
      allow(LaunchProgramMailer).to receive(:with).and_return(mailer)
    end

    subject(:launch_program_job) do
      LaunchProgramJob.perform_now(salesforce_program_id, notification_email, fellow_course_template_id, fellow_course_name, lc_course_template_id, lc_course_name)
    end

    it 'starts the program launch' do
      launch_program_job
      expect(launch_program).to have_received(:run)
    end

    it 'sends success mail if successful' do
      launch_program_job
      expect(mailer).to have_received(:success_email)
    end

    it 'sends failure mail if something bad happens' do
      allow(launch_program).to receive(:run).and_raise('something bad')
      expect(mailer).to receive(:failure_email)
      launch_program_job
    end
  end
end

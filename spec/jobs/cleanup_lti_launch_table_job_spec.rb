# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CleanupLtiLaunchTableJob, type: :job do
  describe '#perform' do

    before(:all) do
      ENV['LTI_LAUNCH_REMEMBER_FOR'] = '1.day' # Use a string b/c that's what ENV vars are passed as
    end

    it 'does nothing if no LtiLaunches older than configured lti_launch_remember_for' do
      launch_now = create(:lti_launch_canvas)
      expect{ CleanupLtiLaunchTableJob.perform_now }.not_to change { LtiLaunch.count }
      expect(LtiLaunch.where(id: launch_now.id)).to exist
    end

    it 'deletes all LtiLaunches if all are older than configured lti_launch_remember_for' do
      launch_2_days_ago = create(:lti_launch_canvas, updated_at: Time.now - 2.days)
      launch_3_days_ago = create(:lti_launch_canvas, updated_at: Time.now - 3.days)
      expect{ CleanupLtiLaunchTableJob.perform_now }.to change { LtiLaunch.count }.from(2).to(0)
      expect(LtiLaunch.where(id: launch_2_days_ago.id)).not_to exist
      expect(LtiLaunch.where(id: launch_3_days_ago.id)).not_to exist
    end

    it 'deletes only LtiLaunches older than configured lti_launch_remember_for' do
      launch_now = create(:lti_launch_canvas)
      launch_2_days_ago = create(:lti_launch_canvas, updated_at: Time.now - 2.days)
      launch_3_days_ago = create(:lti_launch_canvas, updated_at: Time.now - 3.days)
      expect{ CleanupLtiLaunchTableJob.perform_now }.to change { LtiLaunch.count }.from(3).to(1)
      expect(LtiLaunch.where(id: launch_now.id)).to exist
      expect(LtiLaunch.where(id: launch_2_days_ago.id)).not_to exist
      expect(LtiLaunch.where(id: launch_3_days_ago.id)).not_to exist
    end

  end
end

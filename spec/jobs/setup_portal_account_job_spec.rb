# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetupPortalAccountJob, type: :job do
  describe '#perform' do
    let(:portal_setup) { double('SetupPortalAccount', run: nil) }

    before(:each) do
      allow(SetupPortalAccount).to receive(:new).and_return(portal_setup)
    end

    it 'starts the portal account setup process' do
      SetupPortalAccountJob.perform_now(nil)

      expect(portal_setup).to have_received(:run)
    end
  end
end

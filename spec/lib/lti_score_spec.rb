require 'rails_helper'
require 'lti_score'

RSpec.describe LtiScore do

  describe '#new_project_submission' do
    context 'when it''s the first submission' do
      let(:user_id) { 1234 }
      let(:submission_url) { 'https://platformweb/the/url/to/view/submission' }
      it 'generates a new_submission message for the Canvas score API ' do
        allow(DateTime).to receive(:now).and_return(DateTime.now)
        expect(JSON.parse(LtiScore.new_project_submission(user_id, submission_url))).to eq(
          {
            'userId' => user_id.to_s,
            'timestamp' => DateTime.now.iso8601(3), # 3 decimal precision of milliseconds
            'activityProgress' => LtiScore::ActivityProgress::SUBMITTED,
            'gradingProgress' => LtiScore::GradingProgress::PENDING_MANUAL,
            'https://canvas.instructure.com/lti/submission' => {
              'new_submission' => true,
              'submission_type' => 'basic_lti_launch',
              'submission_data' => submission_url
            }
          }
        )
      end
    end
  end
end


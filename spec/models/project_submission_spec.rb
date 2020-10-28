require 'rails_helper'

RSpec.describe ProjectSubmission, type: :model do
  
  describe '#valid?' do
    let(:project_submission) { build(:project_submission) } 

    context 'when valid' do
      it 'allows saving' do
        expect { project_submission.save! }.to_not raise_error
      end
    end

    context 'when no associated user' do
      it 'disallows saving' do
        project_submission.user = nil
        expect { project_submission.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when no associated project' do
      it 'disallows saving' do
        project_submission.base_course_custom_content_version = nil
        expect { project_submission.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

  end
end

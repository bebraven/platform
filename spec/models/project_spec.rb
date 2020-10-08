require 'rails_helper'

RSpec.describe Project, type: :model do
  
  describe '#valid?' do
    let(:project) { build(:project) } 

    context 'when valid' do
      it 'allows saving' do
        expect { project.save! }.to_not raise_error
      end
    end

    context 'when custom_content_version is empty' do
      it 'disallows saving' do
        project.custom_content_version = nil
        expect { project.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

  end
end

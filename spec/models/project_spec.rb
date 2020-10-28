require 'rails_helper'

RSpec.describe Project, type: :model do
  
  describe '#valid?' do
    let(:project) { build(:project) } 

    context 'when valid' do
      it 'allows saving' do
        expect { project.save! }.to_not raise_error
      end
    end
  end
end

require 'rails_helper'

RSpec.describe Rubric, type: :model do
  
  describe '#valid?' do
    let(:rubric) { build(:rubric) } 

    context 'when valid' do
      xit 'allows saving' do
        expect { rubric.save! }.to_not raise_error
      end
    end

    context 'when points_possible is empty' do
      xit 'disallows saving' do
        rubric.points_possible = nil
        expect { rubric.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when no associated project' do
      xit 'disallows saving' do
        rubric.project = nil
        expect { rubric.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end

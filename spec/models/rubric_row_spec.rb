require 'rails_helper'

RSpec.describe RubricRow, type: :model do
  
  describe '#valid?' do
    let(:rubric_row) { build(:rubric_row) } 

    context 'when valid' do
      xit 'allows saving' do
        expect { rubric_row.save! }.to_not raise_error
      end
    end

    context 'when points_possible is empty' do
      xit 'disallows saving' do
        rubric_row.points_possible = nil
        expect { rubric_row.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when criterion is empty' do
      xit 'disallows saving' do
        rubric_row.criterion = nil
        expect { rubric_row.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when position is empty' do
      xit 'disallows saving' do
        rubric_row.position = nil
        expect { rubric_row.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when no associated category' do
      xit 'disallows saving' do
        rubric_row.rubric_row_category = nil
        expect { rubric_row.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end

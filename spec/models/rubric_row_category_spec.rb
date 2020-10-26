require 'rails_helper'

RSpec.describe RubricRowCategory, type: :model do
  
  describe '#valid?' do
    let(:rubric_row_category) { build(:rubric_row_category) } 

    context 'when valid' do
      xit 'allows saving' do
        expect { rubric_row_category.save! }.to_not raise_error
      end
    end

    context 'when position is empty' do
      xit 'disallows saving' do
        rubric_row_category.position = nil
        expect { rubric_row_category.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when no associated rubric' do
      xit 'disallows saving' do
        rubric_row_category.rubric = nil
        expect { rubric_row_category.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end

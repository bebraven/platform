require 'rails_helper'

RSpec.describe RubricRowRating, type: :model do
  
  describe '#valid?' do
    let(:rubric_row_rating) { build(:rubric_row_rating) }

    context 'when valid' do
      xit 'allows saving' do
        expect { rubric_row_rating.save! }.to_not raise_error
      end
    end

    context 'when points_value is empty' do
      xit 'disallows saving' do
        rubric_row_rating.points_value = nil
        expect { rubric_row_rating.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when description is empty' do
      xit 'disallows saving' do
        rubric_row_rating.description = nil
        expect { rubric_row_rating.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when no associated rubric_row' do
      xit 'disallows saving' do
        rubric_row_rating.rubric_row = nil
        expect { rubric_row_rating.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end

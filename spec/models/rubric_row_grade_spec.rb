require 'rails_helper'

RSpec.describe RubricRowGrade, type: :model do
 
  describe '#valid?' do
    let(:rubric_row_grade) { build(:rubric_row_grade) } 

    context 'when valid' do
      xit 'allows saving' do
        expect { rubric_row_grade.save! }.to_not raise_error
      end
    end

    context 'when points_given is empty' do
      xit 'disallows saving' do
        rubric_row_grade.points_given = nil
        expect { rubric_row_grade.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when no associated rubric_grade' do
      xit 'disallows saving' do
        rubric_row_grade.rubric_grade = nil
        expect { rubric_row_grade.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when no associated rubric_row' do
      xit 'disallows saving' do
        rubric_row_grade.rubric_row = nil
        expect { rubric_row_grade.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end

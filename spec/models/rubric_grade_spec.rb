require 'rails_helper'

RSpec.describe RubricGrade, type: :model do
  
  describe '#valid?' do
    let(:rubric_grade) { build(:rubric_grade) } 

    context 'when valid' do
      xit 'allows saving' do
        expect { rubric_grade.save! }.to_not raise_error
      end
    end

    context 'when no associated rubric' do
      xit 'disallows saving' do
        rubric_grade.rubric = nil
        expect { rubric_grade.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when no associated project_submission' do
      xit 'disallows saving' do
        rubric_grade.project_submission = nil
        expect { rubric_grade.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

  end
end

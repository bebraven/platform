require 'rails_helper'

RSpec.describe GradeCategory, type: :model do
  
  describe '#valid?' do
    let(:grade_category) { build(:grade_category) } 

    context 'when valid' do
      it 'allows saving' do
        expect { grade_category.save! }.to_not raise_error
      end
    end

    context 'when name is empty' do
      it 'disallows saving' do
        grade_category.name = nil
        expect { grade_category.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when percent_of_grade is empty' do
      it 'disallows saving' do
        grade_category.percent_of_grade = nil
        expect { grade_category.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when percent_of_grade greater than 1' do
      it 'disallows saving' do
        grade_category.percent_of_grade = 1.1
        expect { grade_category.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when no associated base_course' do
      it 'disallows saving' do
        grade_category.base_course = nil
        expect { grade_category.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  # TODO: write test where the sum total of all project and lessons in a category exceed 100% and implement that validation

  end
end

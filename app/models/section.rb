class Section < ApplicationRecord

  belongs_to :logistic
  belongs_to :course, -> {
    where(base_courses: { type: 'Course' })
  }, foreign_key: :base_course_id

  before_validation { name.try(:strip!) }

  has_many :user_sections
  has_many :users, through: :user_sections do
    def only_fellows
      merge(UserSection.enrolled)
    end

    def only_lcs
      merge(UserSection.facillitates)
    end

    def only_tas
      merge(UserSection.assists)
    end
  end
end

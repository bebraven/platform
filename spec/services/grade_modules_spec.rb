# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GradeModules do

  describe "#run" do

    before :each do
      allow(GradeModules).to receive(:grade_course).and_return(nil)
    end

    context "with no running programs" do
      # TODO: set up SF mock response

      xit "exits early" do
        # TODO
      end
    end

    context "with some running programs" do
      # TODO: set up SF mock response

      context "with no interactions that match the courses" do
        # TODO
        xit "exits early" do
        end
      end

      context "with interactions that match the courses" do
        # TODO

        xit "calls grade_course once for each course with interactions" do
        end

        xit "doesn't call grade_course for courses that have no interactions" do
        end
      end
    end
  end  # run

  describe "#grade_course" do

    before :each do
      allow(GradeModules).to receive(:grade_course).and_return(nil)
    end

    context "with no sections in course" do
      # TODO
      xit "gets empty user_ids" do
      end
    end

    context "with no enrolled users in course" do
      # TODO
      xit "gets empty user_ids" do
      end
    end

    context "with no module versions in course" do
      # TODO
      xit "gets empty canvas_assignment_ids" do
      end
    end

    context "with proper setup" do
      xit "calls grade_assignment once for each assignment with correct user_ids" do
      end
    end
  end  # grade_course

  describe "#grade_assignment" do

    context "with no matching interactions for assignment" do
      # TODO
      xit "exits early" do
      end
    end

    context "with matching interactions for assignment" do
      # TODO

      shared_examples "runs pre-compute tasks" do
        xscenario "calls due_date_for_user correctly for each user" do
        end

        xscenario "fetches interactions for each user" do
        end
      end

      shared_examples "computes and updates grades" do
        xscenario "calls due_date_for_user correctly for each user" do
        end

        xscenario "fetches interactions for each user" do
        end

        xscenario "calls compute_grade correctly for each user" do
        end

        xscenario "computes the correct grades" do
        end

        xscenario "calls update_grades once" do
        end

        xscenario "marks matching interactions before max_id as old" do
        end
      end

      context "with no matching interactions for user, running before due_date" do
        it_behaves_like "runs pre-compute tasks"

        xit "exits early" do
        end
      end

      context "with no matching interactions for user, running after due_date" do
        it_behaves_like "runs pre-compute tasks"
        it_behaves_like "computes and updates grades"
      end

      context "with matching interactions for user" do
        it_behaves_like "runs pre-compute tasks"
        it_behaves_like "computes and updates grades"
      end
    end

  end  # grade_assignment
end

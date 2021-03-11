# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GradeModules do

  let(:grade_modules) { GradeModules.new }
  let(:sf_client) { double(SalesforceAPI) }
  # Default: no programs. Override in context below where appropriate.
  let(:sf_programs) { create(:salesforce_current_and_future_programs) }

  describe "#run" do
    subject { grade_modules.run }

    context "with no running programs" do
      before :each do
        allow(grade_modules).to receive(:grade_course).and_return(nil)

        allow(sf_client)
          .to receive(:get_current_and_future_accelerator_programs)
          .and_return(sf_programs)
        allow(SalesforceAPI).to receive(:client).and_return(sf_client)
      end

      it "exits early" do
        # Stub Course.where so we can check if it was called.
        allow(Course).to receive(:where)

        subject

        expect(sf_client).to have_received(:get_current_and_future_accelerator_programs)
        # We should exit before Course.where gets called.
        expect(Course).not_to have_received(:where)
      end
    end

    context "with some running programs" do
      let(:course) { create(:course) }
      let(:sf_programs) { create(:salesforce_current_and_future_programs, canvas_course_ids: [course.canvas_course_id]) }

      context "with no interactions that match the courses" do
        before :each do
          allow(grade_modules).to receive(:grade_course).and_return(nil)

          allow(sf_client)
            .to receive(:get_current_and_future_accelerator_programs)
            .and_return(sf_programs)
          allow(SalesforceAPI).to receive(:client).and_return(sf_client)

          # Create some non-matching interactions.
          create(:progressed_module_interaction, canvas_course_id: course.canvas_course_id + 1)
          create(:progressed_module_interaction, canvas_course_id: course.canvas_course_id + 1)
        end

        it "exits early" do
          subject

          expect(sf_client).to have_received(:get_current_and_future_accelerator_programs)
          # We should exit before grade_course gets called.
          expect(grade_modules).not_to have_received(:grade_course)
        end
      end

      context "with interactions that match the courses" do
        # Two running programs, two courses, arbitrary Canvas IDs.
        let(:course1) { create(:course, canvas_course_id: 55) }
        let(:course2) { create(:course, canvas_course_id: 56) }
        let(:course3) { create(:course, canvas_course_id: 57) }
        let(:sf_programs) { create(:salesforce_current_and_future_programs,
          canvas_course_ids: [
            course1.canvas_course_id,
            course2.canvas_course_id,
            course3.canvas_course_id,
          ]
        ) }
        # Be sure to adjust this if you change `interactions` below.
        let(:courses_with_interactions) { [course1, course2] }
        # Create some matching interactions for the courses.
        let!(:interactions) { [
          create(:progressed_module_interaction, canvas_course_id: course1.canvas_course_id),
          create(:progressed_module_interaction, canvas_course_id: course1.canvas_course_id),
          create(:progressed_module_interaction, canvas_course_id: course2.canvas_course_id),
        ] }

        before :each do
          allow(grade_modules).to receive(:grade_course).and_return(nil)

          allow(sf_client)
            .to receive(:get_current_and_future_accelerator_programs)
            .and_return(sf_programs)
          allow(SalesforceAPI).to receive(:client).and_return(sf_client)
        end

        it "calls grade_course once for each course with interactions" do
          subject

          expect(grade_modules)
            .to have_received(:grade_course)
            .exactly(courses_with_interactions.count)
            .times
        end

        it "doesn't call grade_course for courses that have no interactions" do
          subject

          expect(grade_modules)
            .not_to have_received(:grade_course)
            .with(course3)
        end
      end
    end
  end  # run

  describe "#grade_course" do
    subject { grade_modules.grade_course(course) }

    let(:course) { create(:course) }

    context "with no sections in course" do
      before :each do
        allow(grade_modules).to receive(:grade_course).and_return(nil)
      end

      # TODO
      xit "gets empty user_ids" do
      end
    end

    context "with no enrolled users in course" do
      before :each do
        allow(grade_modules).to receive(:grade_course).and_return(nil)
      end

      # TODO
      xit "gets empty user_ids" do
      end
    end

    context "with no module versions in course" do
      before :each do
        allow(grade_modules).to receive(:grade_course).and_return(nil)
      end

      # TODO
      xit "gets empty canvas_assignment_ids" do
      end
    end

    context "with proper setup" do
      before :each do
        allow(grade_modules).to receive(:grade_course).and_return(nil)
      end

      xit "calls grade_assignment once for each assignment with correct user_ids" do
      end
    end
  end  # grade_course

  describe "#grade_assignment" do
    subject { grade_modules.grade_assignment(canvas_assignment_id, user_ids) }

    # Arbitrary Canvas ID.
    let(:canvas_assignment_id) { 55 }
    let(:user) { create(:fellow_user) }
    let(:user_ids) { [ user.id ] }

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

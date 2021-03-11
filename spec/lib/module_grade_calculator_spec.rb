require 'rails_helper'
require 'module_grade_calculator'

RSpec.describe ModuleGradeCalculator do

  let(:activity_id) { 'someactivityid' }
  let(:course) { create(:course) }
  let(:section) { create(:section_with_canvas_id, course: course) }
  let(:user) { create(:fellow_user, section: section) }
  let(:rise360_module_version) { create(:rise360_module_version) }
  let(:course_rise360_module_version) { create(:course_rise360_module_version,
    course: course,
    rise360_module_version: rise360_module_version,
  ) }
  let(:canvas_assignment_id) { course_rise360_module_version.canvas_assignment_id }
  let(:assignment_overrides) { [ create(:canvas_assignment_override_section,
    assignment_id: canvas_assignment_id,
    course_section_id: section.canvas_section_id,
  ) ] }

  describe "#grade_weights" do
    it "sums up to 1" do
      total = 0.0
      ModuleGradeCalculator.grade_weights.each do |key, weight|
        total += weight
      end
      expect(total).to eq(1.0)
    end
  end  # grade_weights 

  describe "#compute_grade" do
    context "empty Rise360ModuleInteraction table" do
      it "returns 0" do
        interactions = Rise360ModuleInteraction.where(new: true)
        expect(interactions).to be_empty

        grade = ModuleGradeCalculator.compute_grade(user.id, canvas_assignment_id, activity_id)
        expect(grade).to eq(0.0)
      end
    end

    context "with 100s for everything" do
      before :each do
        # Need a new interaction to trigger computation
        interaction = Rise360ModuleInteraction.create!(
          verb: Rise360ModuleInteraction::PROGRESSED,
          user: user,
          canvas_course_id: 333,
          canvas_assignment_id: canvas_assignment_id,
          activity_id: activity_id,
          progress: 100,
          new: true,
        )

        # Stub out grade computation
        allow(ModuleGradeCalculator)
          .to receive(:grade_mastery_quiz)
          .and_return(100)
        allow(ModuleGradeCalculator)
          .to receive(:grade_module_engagement)
          .and_return(interaction.progress)
        allow(ModuleGradeCalculator)
          .to receive(:grade_completed_on_time)
          .and_return(100)
      end

      it "grades engagement and quiz" do
        grade = ModuleGradeCalculator.compute_grade(user.id, canvas_assignment_id, assignment_overrides)

        # Called each grading method
        expect(ModuleGradeCalculator)
          .to have_received(:grade_module_engagement)
          .once
        expect(ModuleGradeCalculator)
          .to have_received(:grade_mastery_quiz)
          .once

        expect(grade).to eq(100)
      end
    end

    context "with no quiz" do
      before :each do
        # Need a new engagement interaction to trigger computation
        interaction = Rise360ModuleInteraction.create!(
          verb: Rise360ModuleInteraction::PROGRESSED,
          user: user,
          canvas_course_id: 333,
          canvas_assignment_id: canvas_assignment_id,
          activity_id: activity_id,
          progress: 100,
          new: true,
        )

        # Stub out grade computation
        allow(rise360_module_version)
          .to receive(:quiz_questions)
          .and_return(0)
        allow(ModuleGradeCalculator)
          .to receive(:grade_module_engagement)
          .and_return(interaction.progress)
        allow(Rise360ModuleVersion)
          .to receive(:find)
          .and_return(rise360_module_version)
      end

      it "only grades engagement if no quiz" do
        # Test that the mastery part of grading is skipped
        expect(ModuleGradeCalculator)
          .not_to receive(:grade_mastery_quiz)

        grade = ModuleGradeCalculator.compute_grade(user.id, canvas_assignment_id, assignment_overrides)

        # Called each grading method
        expect(ModuleGradeCalculator)
          .to have_received(:grade_module_engagement)
          .once

        expect(grade).to eq(100)
      end
    end

    context "with half scores for everything" do
      # Two total questions.
      let(:rise360_module_version) { create(:rise360_module_version, quiz_questions: 2) }

      before :each do
        # 50% progress.
        Rise360ModuleInteraction.create!(
          verb: Rise360ModuleInteraction::PROGRESSED,
          user: user,
          canvas_course_id: course.canvas_course_id,
          canvas_assignment_id: canvas_assignment_id,
          activity_id: activity_id,
          progress: 50,
          new: true,
        )

        # One correct, one incorrect.
        Rise360ModuleInteraction.create!(
          verb: Rise360ModuleInteraction::ANSWERED,
          user: user,
          canvas_course_id: 333,
          canvas_assignment_id: canvas_assignment_id,
          activity_id: "#{activity_id}/somequizid/firstquestion",
          success: true,
          new: true,
        )
        Rise360ModuleInteraction.create!(
          verb: Rise360ModuleInteraction::ANSWERED,
          user: user,
          canvas_course_id: 333,
          canvas_assignment_id: canvas_assignment_id,
          activity_id: "#{activity_id}/somequizid/secondquestion",
          success: false,
          new: true,
        )
      end

      it "computes the correct grade" do
        grade = ModuleGradeCalculator.compute_grade(user.id, canvas_assignment_id, assignment_overrides)
        expect(grade).to eq( 50*0.4 + 50*0.4 + 0*0.2 )
      end
    end

    context "with all old interactions" do
      # Two total questions.
      let(:rise360_module_version) { create(:rise360_module_version, quiz_questions: 2) }

      before :each do
        # 50% progress.
        Rise360ModuleInteraction.create!(
          verb: Rise360ModuleInteraction::PROGRESSED,
          user: user,
          canvas_course_id: course.canvas_course_id,
          canvas_assignment_id: canvas_assignment_id,
          activity_id: activity_id,
          progress: 50,
          new: false,
        )

        # One correct, one incorrect.
        Rise360ModuleInteraction.create!(
          verb: Rise360ModuleInteraction::ANSWERED,
          user: user,
          canvas_course_id: 333,
          canvas_assignment_id: canvas_assignment_id,
          activity_id: "#{activity_id}/somequizid/firstquestion",
          success: true,
          new: false,
        )
        Rise360ModuleInteraction.create!(
          verb: Rise360ModuleInteraction::ANSWERED,
          user: user,
          canvas_course_id: 333,
          canvas_assignment_id: canvas_assignment_id,
          activity_id: "#{activity_id}/somequizid/secondquestion",
          success: false,
          new: false,
        )
      end

      it "still computes the correct grade" do
        grade = ModuleGradeCalculator.compute_grade(user.id, canvas_assignment_id, assignment_overrides)
        expect(grade).to eq( 50*0.4 + 50*0.4 + 0*0.2 )
      end
    end

    context "with full engagement and partial mastery" do
      # Two total questions.
      let(:rise360_module_version) { create(:rise360_module_version, quiz_questions: 2) }

      before :each do
        # 100% progress.
        Rise360ModuleInteraction.create!(
          verb: Rise360ModuleInteraction::PROGRESSED,
          user: user,
          canvas_course_id: course.canvas_course_id,
          canvas_assignment_id: canvas_assignment_id,
          activity_id: activity_id,
          progress: 100,
          new: true,
        )

        # One correct, one incorrect.
        Rise360ModuleInteraction.create!(
          verb: Rise360ModuleInteraction::ANSWERED,
          user: user,
          canvas_course_id: 333,
          canvas_assignment_id: canvas_assignment_id,
          activity_id: "#{activity_id}/somequizid/firstquestion",
          success: true,
          new: true,
        )
        Rise360ModuleInteraction.create!(
          verb: Rise360ModuleInteraction::ANSWERED,
          user: user,
          canvas_course_id: 333,
          canvas_assignment_id: canvas_assignment_id,
          activity_id: "#{activity_id}/somequizid/secondquestion",
          success: false,
          new: true,
        )
      end

      it "computes the correct grade" do
        grade = ModuleGradeCalculator.compute_grade(user.id, canvas_assignment_id, assignment_overrides)
        expect(grade).to eq( 100*0.4 + 50*0.4 + 100*0.2 )
      end
    end

    context "with full mastery and partial engagenemt" do
      # Two total questions.
      let(:rise360_module_version) { create(:rise360_module_version, quiz_questions: 2) }

      before :each do
        # 50% progress.
        Rise360ModuleInteraction.create!(
          verb: Rise360ModuleInteraction::PROGRESSED,
          user: user,
          canvas_course_id: course.canvas_course_id,
          canvas_assignment_id: canvas_assignment_id,
          activity_id: activity_id,
          progress: 50,
          new: true,
        )

        # Both correct.
        Rise360ModuleInteraction.create!(
          verb: Rise360ModuleInteraction::ANSWERED,
          user: user,
          canvas_course_id: 333,
          canvas_assignment_id: canvas_assignment_id,
          activity_id: "#{activity_id}/somequizid/firstquestion",
          success: true,
          new: true,
        )
        Rise360ModuleInteraction.create!(
          verb: Rise360ModuleInteraction::ANSWERED,
          user: user,
          canvas_course_id: 333,
          canvas_assignment_id: canvas_assignment_id,
          activity_id: "#{activity_id}/somequizid/secondquestion",
          success: true,
          new: true,
        )
      end

      it "computes the correct grade" do
        grade = ModuleGradeCalculator.compute_grade(user.id, canvas_assignment_id, assignment_overrides)
        expect(grade).to eq( 50*0.4 + 100*0.4 + 0*0.2 )
      end
    end
  end  # compute_grade

  describe "#grade_module_engagement" do
    context "module engagement grade" do
      it "returns 0 for no interactions" do
        interactions = Rise360ModuleInteraction
          .where(verb: Rise360ModuleInteraction::PROGRESSED)
        expect(interactions).to be_empty

        grade = ModuleGradeCalculator.grade_module_engagement(interactions)
        expect(grade).to eq(0)
      end

      it "returns progress" do
        interaction = Rise360ModuleInteraction.create!(
          verb: Rise360ModuleInteraction::PROGRESSED,
          user: user,
          canvas_course_id: 333,
          canvas_assignment_id: canvas_assignment_id,
          activity_id: activity_id,
          progress: rand(0..100),
          new: true,
        )

        interactions = Rise360ModuleInteraction
          .where(verb: Rise360ModuleInteraction::PROGRESSED)

        grade = ModuleGradeCalculator.grade_module_engagement(interactions)
        expect(grade).to eq(interaction.progress)
      end

      it "returns maximum progress" do
        # Generate random progress for interactions
        progress = [ rand(0..100), rand(0..100) ]
        maximum = progress.max

        progress.each do |value|
          Rise360ModuleInteraction.create!(
            verb: Rise360ModuleInteraction::PROGRESSED,
            user: user,
            canvas_course_id: 333,
            canvas_assignment_id: canvas_assignment_id,
            activity_id: activity_id,
            progress: value,
            new: value != maximum, # Maximum value has new: false
          )
        end

        interactions = Rise360ModuleInteraction
          .where(verb: Rise360ModuleInteraction::PROGRESSED)

        grade = ModuleGradeCalculator.grade_module_engagement(interactions)
        expect(grade).to eq(maximum)
      end
    end
  end  # grade_module_engagement

  describe "#grade_mastery_quiz" do
    context "mastery quiz" do 
      it "returns percent of correct answers" do
        # Use denominator that generates remainder to test division
        quiz_questions = 3

        interactions = Rise360ModuleInteraction
          .where(verb: Rise360ModuleInteraction::ANSWERED)
        grade = ModuleGradeCalculator.grade_mastery_quiz(interactions, quiz_questions)
        expect(grade).to eq(0)

        Rise360ModuleInteraction.create!(
          verb: Rise360ModuleInteraction::ANSWERED,
          user: user,
          canvas_course_id: 333,
          canvas_assignment_id: canvas_assignment_id,
          activity_id: "#{activity_id}/somequizid/firstquestion",
          success: true,
          new: true,
        )
        interactions = Rise360ModuleInteraction
          .where(verb: Rise360ModuleInteraction::ANSWERED)
        grade = ModuleGradeCalculator.grade_mastery_quiz(interactions, quiz_questions)
        expect(grade).to eq(1.0/quiz_questions * 100)

        Rise360ModuleInteraction.create!(
          verb: Rise360ModuleInteraction::ANSWERED,
          user: user,
          canvas_course_id: 333,
          canvas_assignment_id: canvas_assignment_id,
          activity_id: "#{activity_id}/somequizid/secondquestion",
          success: true,
          new: true,
        )
        interactions = Rise360ModuleInteraction
          .where(verb: Rise360ModuleInteraction::ANSWERED)
        grade = ModuleGradeCalculator.grade_mastery_quiz(interactions, quiz_questions)
        expect(grade).to eq(2.0/quiz_questions * 100)
      end

      it "uses success from most recent interaction" do
        quiz_question_id = "#{activity_id}/somequizid/somequestionid"
        timestamp = Time.now.to_i

        # Initially a correct answer
        Rise360ModuleInteraction.create!(
          verb: Rise360ModuleInteraction::ANSWERED,
          user: user,
          canvas_course_id: 333,
          canvas_assignment_id: canvas_assignment_id,
          activity_id: "#{quiz_question_id}_#{timestamp}",
          success: true,
          new: true,
        )

        # Wrong answer later
        Rise360ModuleInteraction.create!(
          verb: Rise360ModuleInteraction::ANSWERED,
          user: user,
          canvas_course_id: 333,
          canvas_assignment_id: canvas_assignment_id,
          activity_id: "#{quiz_question_id}_#{timestamp + 1}",
          success: false, # User later go the same question wrong
          new: true,
        )

        interactions = Rise360ModuleInteraction
          .where(verb: Rise360ModuleInteraction::ANSWERED)

        grade = ModuleGradeCalculator.grade_mastery_quiz(interactions, 2)
        expect(grade).to eq(0)
      end
    end
  end  # grade_mastery_quiz

  describe "#due_date_for_user" do
    subject { ModuleGradeCalculator.due_date_for_user(user.id, assignment_overrides) }
    # Arbitrary Canvas IDs.
    let(:canvas_user_id) { 55 }
    let(:canvas_section_id) { 55 }
    let(:section) { create(:section, canvas_section_id: canvas_section_id) }
    # User and section dates don't match, so we can tell them apart.
    let(:user_due_date) { 1.days.from_now.utc.to_time.iso8601 }
    let(:section_due_date) { 5.days.from_now.utc.to_time.iso8601 }

    context "with empty overrides" do
      # Note: I manually verified get_assignment_overrides returns an empty
      # list when there are no overrides for the assignment.
      let(:assignment_overrides) { [] }

      it { is_expected.to eq(nil) }
    end

    context "with no matching override" do
      let(:assignment_overrides) { [
        create(:canvas_assignment_override_section,
          # NOT the user's section.
          course_section_id: section.canvas_section_id + 1,
        ),
        create(:canvas_assignment_override_user,
          # NOT the user's ID.
          student_ids: [ user.canvas_user_id + 1 ],
        ),
      ] }

      it { is_expected.to eq(nil) }
    end

    context "with user-match override" do
      let(:assignment_override_user) { create(:canvas_assignment_override_user,
        # The user's ID.
        student_ids: [ canvas_user_id ],
        due_at: user_due_date,
      ) }
      let(:assignment_override_section) { create(:canvas_assignment_override_section,
        # NOT the user's section.
        course_section_id: canvas_section_id + 1,
        due_at: section_due_date,
      ) }
      let(:assignment_overrides) { [
        assignment_override_user,
        assignment_override_section,
      ] }

      context "with user not in any sections" do
        let(:user) { create(:registered_user) }

        before :each do
          user.update!(canvas_user_id: canvas_user_id)
        end

        it { is_expected.to eq(user_due_date) }
      end

      context "with user in a non-matching section" do
        before :each do
          user.update!(canvas_user_id: canvas_user_id)
        end

        it { is_expected.to eq(user_due_date) }
      end
    end

    context "with section-match override" do
      let(:assignment_override_user) { create(:canvas_assignment_override_user,
        # NOT the user's ID.
        student_ids: [ canvas_user_id + 1 ],
        due_at: user_due_date,
      ) }
      let(:assignment_override_section) { create(:canvas_assignment_override_section,
        # The user's section.
        course_section_id: canvas_section_id,
        due_at: section_due_date,
      ) }
      let(:assignment_overrides) { [
        assignment_override_user,
        assignment_override_section,
      ] }

      before :each do
        user.update!(canvas_user_id: canvas_user_id)
      end

      it { is_expected.to eq(section_due_date) }
    end

    context "with user-match and section-match overrides, user-match last" do
      let(:user_due_date) { 5.days.from_now.utc.to_time.iso8601 }
      let(:section_due_date) { 1.day.from_now.utc.to_time.iso8601 }
      let(:assignment_override_user) { create(:canvas_assignment_override_user,
        # The user's ID.
        student_ids: [ canvas_user_id ],
        due_at: user_due_date,
      ) }
      let(:assignment_override_section) { create(:canvas_assignment_override_section,
        # The user's section.
        course_section_id: canvas_section_id,
        due_at: section_due_date,
      ) }
      let(:assignment_overrides) { [
        assignment_override_user,
        assignment_override_section,
        # Add in some extra overrides for good measure.
        create(:canvas_assignment_override_user,
          student_ids: [ canvas_user_id ],
          due_at: 3.days.from_now.utc.to_time.iso8601
        ),
        create(:canvas_assignment_override_user,
          student_ids: [ canvas_user_id + 1 ],
          due_at: 100.days.from_now.utc.to_time.iso8601
        ),
        create(:canvas_assignment_override_section,
          course_section_id: canvas_section_id,
          due_at: 3.days.from_now.utc.to_time.iso8601
        ),
      ] }

      before :each do
        user.update!(canvas_user_id: canvas_user_id)
      end

      it { is_expected.to eq(user_due_date) }
    end

    context "with user-match and section-match overrides, section-match last" do
      let(:user_due_date) { 1.day.from_now.utc.to_time.iso8601 }
      let(:section_due_date) { 5.days.from_now.utc.to_time.iso8601 }
      let(:assignment_override_user) { create(:canvas_assignment_override_user,
        # The user's ID.
        student_ids: [ canvas_user_id ],
        due_at: user_due_date,
      ) }
      let(:assignment_override_section) { create(:canvas_assignment_override_section,
        # The user's section.
        course_section_id: canvas_section_id,
        due_at: section_due_date,
      ) }
      let(:assignment_overrides) { [
        assignment_override_user,
        assignment_override_section,
        # Add in some extra overrides for good measure.
        create(:canvas_assignment_override_user,
          student_ids: [ canvas_user_id ],
          due_at: 3.days.from_now.utc.to_time.iso8601
        ),
        create(:canvas_assignment_override_user,
          student_ids: [ canvas_user_id + 1 ],
          due_at: 100.days.from_now.utc.to_time.iso8601
        ),
        create(:canvas_assignment_override_section,
          course_section_id: canvas_section_id,
          due_at: 3.days.from_now.utc.to_time.iso8601
        ),
      ] }

      before :each do
        user.update!(canvas_user_id: canvas_user_id)
      end

      it { is_expected.to eq(section_due_date) }
    end
  end  # due_date_for_user

  describe "#grade_completed_on_time" do
    let(:interactions) { Rise360ModuleInteraction.all }
    let(:due_date_obj) { 1.day.from_now.utc }
    let(:due_date) { due_date_obj.to_time.iso8601 }

    shared_examples 'incomplete module' do
      xscenario 'returns 0' do
        on_time_grade = ModuleGradeCalculator.grade_completed_on_time(interactions, due_date)
        expect(on_time_grade).to eq(0)
      end
    end

    shared_examples 'completed module' do
      xscenario 'returns 100' do
        on_time_grade = ModuleGradeCalculator.grade_completed_on_time(interactions, due_date)
        expect(on_time_grade).to eq(100)
      end
    end

    context "with no interactions" do
      # TODO: set up context
      it_behaves_like "incomplete module"
    end

    context "with only interactions after due date" do
      # TODO: set up context
      it_behaves_like "incomplete module"
    end

    context "with some interactions before, completed interaction after due date" do
      # TODO: set up context
      it_behaves_like "incomplete module"
    end

    context "with completed interaction before due date" do
      # TODO: set up context
      it_behaves_like "completed module"
    end
  end  # grade_completed_on_time
end

require 'rails_helper'
require 'module_grade_calculator'

RSpec.describe ModuleGradeCalculator do

  let(:activity_id) { 'someactivityid' }
  let(:course) { create(:course) }
  let(:section) { create(:section_with_canvas_id, course: course) }
  let(:user) { create(:fellow_user, section: section) }
  let(:canvas_assignment_id) { course_rise360_module_version.canvas_assignment_id }
  let(:course_rise360_module_version) { create(:course_rise360_module_version, course: course) }
  let(:rise360_module_version) { course_rise360_module_version.rise360_module_version }
  let(:assignment_overrides) { [ create(:canvas_assignment_override_section,
    assignment_id: canvas_assignment_id,
    course_section_id: section.canvas_section_id,
    # Arbitrary future date.
    due_at: 3.days.from_now.utc.to_time.iso8601,
  ) ] }

  describe "grade_weights" do
    it "sums up to 1" do
      total = 0.0
      ModuleGradeCalculator.grade_weights.each do |key, weight|
        total += weight
      end
      expect(total).to eq(1.0)
    end
  end  # grade_weights 

  describe "compute_grade" do
    context "empty Rise360ModuleInteraction table" do
      it "returns 0" do
        interactions = Rise360ModuleInteraction.where(new: true)
        expect(interactions).to be_empty

        grade = ModuleGradeCalculator.compute_grade(user.id, canvas_assignment_id, activity_id)
        expect(grade).to eq(0.0)
      end
    end

    context "total grade" do
      it "grades engagement and quiz" do
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

        grade = ModuleGradeCalculator.compute_grade(user.id, interaction.canvas_assignment_id, assignment_overrides)

        # Called each grading method
        expect(ModuleGradeCalculator)
          .to have_received(:grade_module_engagement)
          .once
        expect(ModuleGradeCalculator)
          .to have_received(:grade_mastery_quiz)
          .once

        expect(grade).to eq(100)
      end

      it "only grades engagement if no quiz" do
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
  end  # compute_grade

  describe "grade_module_engagement" do
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

  describe "grade_mastery_quiz" do
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

  describe "due_date_for_user" do
    context "with empty overrides" do
      # TODO
      xit "returns nil" do
      end
    end

    context "with no matching override" do
      # TODO
      xit "returns nil" do
      end
    end

    context "with user-match override" do
      context "with user not in any sections" do
        # TODO
        xit "returns due date" do
        end
      end

      context "with user in a non-matching section" do
        # TODO
        xit "returns due date" do
        end
      end
    end

    context "with section-match override" do
      # TODO
      xit "returns due date" do
      end
    end

    context "with user-match and section-match overrides, user-match last" do
      # TODO
      xit "returns user-match due date" do
      end
    end

    context "with user-match and section-match overrides, section-match last" do
      # TODO
      xit "returns section-match due date" do
      end
    end
  end  # due_date_for_user

  describe "grade_completed_on_time" do
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

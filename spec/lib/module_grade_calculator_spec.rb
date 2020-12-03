require 'rails_helper'
require 'module_grade_calculator'

RSpec.describe ModuleGradeCalculator do

  describe "computes grade for module" do 

    let(:activity_id) { 'someactivityid' }
    let(:user) { build(:fellow_user) }
    let(:lesson_content) { build(:lesson_content) }

    before(:each) do 
      allow(LessonContent)
        .to receive(:find_by)
        .and_return(lesson_content)

      allow_any_instance_of(LessonContent)
        .to receive(:quiz_questions)
        .and_return(2)
    end

    context "grade weighting" do 
      it "sums up to 1" do
        total = 0.0
        ModuleGradeCalculator.grade_weights.each do |key, weight|
          total += weight
        end
        expect(total).to eq(1.0)
      end
    end

    context "empty Rise360ModuleInteraction table" do
      it "returns 0" do
        interactions = Rise360ModuleInteraction.for_user_and_activity(
          user.id,
          activity_id,
        )
        expect(interactions).to be_empty

        grade = ModuleGradeCalculator.compute_grade(user.id, activity_id)
        expect(grade).to be(0.0)
      end
    end

    context "total grade" do
      it "grades engagement and quiz" do
        # Need a new interaction to trigger computation
        interaction = Rise360ModuleInteraction.create!(
          verb: Rise360ModuleInteraction::PROGRESSED,
          user: user,
          canvas_course_id: 333,
          canvas_assignment_id: 222,
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
          .to receive(:grade_weights)
          .and_return({
            module_engagement: 0.5,
            mastery_quiz: 0.5,
          })

        grade = ModuleGradeCalculator.compute_grade(user.id, activity_id)

        # Called each grading method
        expect(ModuleGradeCalculator)
          .to have_received(:grade_module_engagement)
          .once
        expect(ModuleGradeCalculator)
          .to have_received(:grade_mastery_quiz)
          .once

        # Weighted grades
        expect(ModuleGradeCalculator)
          .to have_received(:grade_weights)
          .at_least(:once)

        expect(grade).to eq(100)
      end
    end

    context "module engagement grade" do
      it "returns 0 for no interactions" do
        interactions = Rise360ModuleInteraction
          .for_user_and_activity(user.id, activity_id)
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
          canvas_assignment_id: 222,
          activity_id: activity_id,
          progress: rand(0..100),
          new: true,
        )

        interactions = Rise360ModuleInteraction
          .for_user_and_activity(user.id, activity_id)
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
            canvas_assignment_id: 222,
            activity_id: activity_id,
            progress: value,
            new: value != maximum, # Maximum value has new: false
          )
        end

        interactions = Rise360ModuleInteraction
          .for_user_and_activity(user.id, activity_id)
          .where(verb: Rise360ModuleInteraction::PROGRESSED)

        grade = ModuleGradeCalculator.grade_module_engagement(interactions)
        expect(grade).to eq(maximum)
      end
    end

    context "mastery quiz" do 
      it "returns percent of correct answers" do
        # Use denominator that generates remainder to test division
        quiz_questions = 3

        interactions = Rise360ModuleInteraction
          .for_user_and_activity(user.id, activity_id)
          .where(verb: Rise360ModuleInteraction::ANSWERED)
        grade = ModuleGradeCalculator.grade_mastery_quiz(interactions, quiz_questions)
        expect(grade).to eq(0)

        Rise360ModuleInteraction.create!(
          verb: Rise360ModuleInteraction::ANSWERED,
          user: user,
          canvas_course_id: 333,
          canvas_assignment_id: 222,
          activity_id: "#{activity_id}/somequizid/firstquestion",
          success: true,
          new: true,
        )
        interactions = Rise360ModuleInteraction
          .for_user_and_activity(user.id, activity_id)
          .where(verb: Rise360ModuleInteraction::ANSWERED)
        grade = ModuleGradeCalculator.grade_mastery_quiz(interactions, quiz_questions)
        expect(grade).to eq(1.0/quiz_questions * 100)

        Rise360ModuleInteraction.create!(
          verb: Rise360ModuleInteraction::ANSWERED,
          user: user,
          canvas_course_id: 333,
          canvas_assignment_id: 222,
          activity_id: "#{activity_id}/somequizid/secondquestion",
          success: true,
          new: true,
        )
        interactions = Rise360ModuleInteraction
          .for_user_and_activity(user.id, activity_id)
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
          canvas_assignment_id: 222,
          activity_id: "#{quiz_question_id}_#{timestamp}",
          success: true,
          new: true,
        )

        # Wrong answer later
        Rise360ModuleInteraction.create!(
          verb: Rise360ModuleInteraction::ANSWERED,
          user: user,
          canvas_course_id: 333,
          canvas_assignment_id: 222,
          activity_id: "#{quiz_question_id}_#{timestamp + 1}",
          success: false, # User later go the same question wrong
          new: true,
        )

        interactions = Rise360ModuleInteraction
          .for_user_and_activity(user.id, activity_id)
          .where(verb: Rise360ModuleInteraction::ANSWERED)

        grade = ModuleGradeCalculator.grade_mastery_quiz(interactions, 2)
        expect(grade).to eq(0)
      end
    end
  end
end

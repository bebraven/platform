module CoursesHelper

  def has_waivers?
    !!@canvas_assignment_info.canvas_waivers_url
  end

  def canvas_waivers_url
    @canvas_assignment_info.canvas_waivers_url
  end

  def canvas_waivers_assignment_id
    @canvas_assignment_info.canvas_waivers_assignment_id
  end

  def has_peer_reviews_assignment?
    !!@canvas_assignment_info.canvas_peer_reviews_url
  end

  def canvas_peer_reviews_url
    @canvas_assignment_info.canvas_peer_reviews_url
  end

  def canvas_peer_reviews_assignment_id
    @canvas_assignment_info.canvas_peer_reviews_assignment_id
  end

  def has_peer_review_results_assignment?
    !!@canvas_assignment_info.canvas_peer_review_results_url
  end

  def canvas_peer_review_results_url
    @canvas_assignment_info.canvas_peer_review_results_url
  end

  def canvas_peer_review_results_assignment_id
    @canvas_assignment_info.canvas_peer_review_results_assignment_id
  end

  def has_preaccelerator_survey?
    !!canvas_preaccelerator_survey_url
  end

  def canvas_preaccelerator_survey_url
    @canvas_assignment_info.canvas_preaccelerator_survey_url
  end

  def canvas_preaccelerator_survey_assignment_id
    @canvas_assignment_info.canvas_preaccelerator_survey_assignment_id
  end

  def has_postaccelerator_survey?
    !!canvas_postaccelerator_survey_url
  end

  def canvas_postaccelerator_survey_url
    @canvas_assignment_info.canvas_postaccelerator_survey_url
  end

  def canvas_postaccelerator_survey_assignment_id
    @canvas_assignment_info.canvas_postaccelerator_survey_assignment_id
  end

  def has_fellow_evaluation?
    !!canvas_fellow_evaluation_url
  end

  def canvas_fellow_evaluation_url
    @canvas_assignment_info.canvas_fellow_evaluation_url
  end

  def canvas_fellow_evaluation_assignment_id
    @canvas_assignment_info.canvas_fellow_evaluation_assignment_id
  end
end

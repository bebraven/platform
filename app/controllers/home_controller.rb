class HomeController < ApplicationController
  layout 'admin'

  before_action :admin_only

  def welcome
    authorize :application, :index?

    @links = [
      { title: 'Portal', path: canvas_url, blank_target: true, is_active: true},
      { title: 'Content Editor', path: new_custom_content_path },
      { title: 'Course Management', path: base_courses_path },
      { title: 'Sync To LMS', path: sync_to_lms_path },
      { title: 'Sync To Join', path: sync_to_join_path },
      { title: 'Sync To Slack', path: sync_to_slack_path },
      { title: 'Sync To Webinar', path: sync_to_webinar_path },
      { title: 'Users', path: users_path }
    ]
  end

  private

  def admin_only
    redirect_to :canvas unless current_user.admin?
  end
end

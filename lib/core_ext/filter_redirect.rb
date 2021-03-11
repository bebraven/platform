# frozen_string_literal: true

module CoreExtensions
  module FilterRedirect

    # Prepend this to ActionDispatch::Response so that it overrides the behavior of
    # ActionDispatch::Http::FilterRedirect in order to only remove the sensitive query
    # parameters instead of filtering the entire path.
    #
    # E.g. show something like this in the logs:
    # Redirected to https://platformweb/course_project_versions/41/project_submissions/new?state=[FILTERED]
    module ParametersOnly

      # Original implementation located at:
      # https://github.com/rails/rails/blob/main/actionpack/lib/action_dispatch/http/filter_redirect.rb
      def filtered_location
        ret = location.gsub(/state\=([^\&]+)/, 'state=[FILTERED]')
        ret = ret.gsub(/auth\=([^\&]+)/, 'auth=[FILTERED]')
        ret
      end

    end

  end
end

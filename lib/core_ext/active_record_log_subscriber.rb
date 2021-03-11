# frozen_string_literal: true

require 'filter_logging'

module CoreExtensions
  module ActiveRecord

    # Prepend this to ActiveRecord::LogSubscriber class so that it overrides the behavior
    # and properly filters logging of SQL statements using Rails.application.config.filter_parameters
    # as the parameters/attributes that should be filtered.
    #
    # E.g. show something like this in the logs:
    # LtiLaunch Load (0.6ms)  SELECT "lti_launches".* FROM "lti_launches"
    #   WHERE "lti_launches"."state" = $1 ASC LIMIT $2  [["state", "[FILTERED]"], ["LIMIT", 1]]
    #
    # Note that ActiveRecord.filter_attributes sounds like it should do this, but it it doesn't
    # work b/c the logging calls inspect on the "binds" and not on the ActiveRecord model itself.
    # See: https://github.com/rails/rails/blob/main/activerecord/lib/active_record/log_subscriber.rb
    module LogSubscriber

      # Original implementation located at:
      # https://github.com/rails/rails/blob/main/activerecord/lib/active_record/log_subscriber.rb
      def render_bind(attr, value)
        case attr
        when ActiveModel::Attribute
          if attr.type.binary? && attr.value
            value = "<#{attr.value_for_database.to_s.bytesize} bytes of binary data>"
          end
        when Array
          attr = attr.first
        else
          attr = nil
        end

        ### Custom implementation here
        value = FilterLogging.filter_sql(attr&.name, value)
        ### End custom implementation

        [attr&.name, value]
      end

    end

  end
end

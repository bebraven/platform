# frozen_string_literal: true

# Used for filtering out the parameters and data that you don't want shown in the logs,
# such as passwords or credit card numbers or the state param (which is like a password).
class FilterLogging

  def self.is_enabled?
    (Rails.env.development? ? false : true)
  end

  # Returns a lambda function meant to be used with Rails.application.config.filter_parameters
  # or ActiveSupport::ParameterFilter. It is responsible for returning the filtered value of a
  # parameter if it contains sensitive data.
  def self.filter_parameters
    return @filter_parameters_lambda if @filter_parameters_lambda

    @filter_parameters_lambda = lambda do |param_name, value|
      return if value.blank?

      # Note: we have to alter the strings in place because we don't have access to
      # the hash to update the key's value

      if param_name == 'state' || param_name.include?('password') || param_name == 'auth'

        value.clear()
        value.insert(0, '[FILTERED]')

      elsif param_name == 'u' || param_name == 'pgu'

        value.gsub!(/state\=([^\&]+)/, 'state=[FILTERED]')

      elsif param_name == 'restiming'

        value.gsub!(/auth\=LtiState([^\"\&]+)/, 'auth=[FILTERED]')
        value.gsub!(/state\=([^\"\&]+)/, 'state=[FILTERED]')

      end
    end
  end

  # Filters the value out of ActiveRecord SQL logging for sensitive columns
  def self.filter_sql(column_name, column_value)
    if column_name == 'state' || column_name.include?('password')
      '[FILTERED]'
    else
      column_value
    end
  end

  # Filters out sensitive information from the payloads sent to Honeycomb
  # using the above Rails.application.config.filter_parameters Proc.
  # See: https://docs.honeycomb.io/getting-data-in/ruby/beeline/#rails
  #
  # This just takes every Honeycomb field we know of that can have the state/password/etc
  # in it and runs the appropriate regex/filtering logic above by translating the Honeycomb
  # field to the corrseponding controller param that holds the sensitive data in the same
  # or similar format.
  def self.filter_honeycomb_data(fields)

# TODO: check Honeycomb for passwords during password reset or registration. Also, look for session IDs
# and other tokens, like LinkedIn access token confirmation_token

    parameter_filter = ActiveSupport::ParameterFilter.new([FilterLogging.filter_parameters])

    if fields['name'] == 'http_request'
      if fields.has_key?('request.query_string')
        fields['request.query_string'] = parameter_filter.filter_param('restiming', fields['request.query_string'])
      end
    end

    # These are values coming from HoneycombJsController generated spans
    # from Boomerang payloads.
    if fields['name'].start_with?('javascript')
      fields['request.query_string'] = parameter_filter.filter_param('restiming', fields['request.query_string']) if fields.has_key?('request.query_string')
      fields['pgu'] = parameter_filter.filter_param('u', fields['pgu']) if fields.has_key?('pgu')
      fields['u'] = parameter_filter.filter_param('u', fields['u']) if fields.has_key?('u')
      fields['restiming'] = parameter_filter.filter_param('restiming', fields['restiming']) if fields.has_key?('restiming')
      fields.delete('state') if fields.has_key?('state')
    end

    if fields['name'] == 'process_action.action_controller'
      if fields.has_key?('process_action.action_controller.params')
        fields['process_action.action_controller.params'] = parameter_filter.filter_param('restiming', fields['process_action.action_controller.params'])
      end
      if fields.has_key?('process_action.action_controller.path')
        fields['process_action.action_controller.path'] = parameter_filter.filter_param('u', fields['process_action.action_controller.path'])
      end

    end

# TODO: this may not be necessary now that I have the filter_sql stuff in place above?
    # Get rid of the value of the state param when querying the LtiLaunch table.
    if fields['name'] == 'sql.active_record' && fields['sql.active_record.name']&.include?('LtiLaunch')
      fields['sql.active_record.type_casted_binds'] = '[FILTERED]'
    end

    fields
  end

end

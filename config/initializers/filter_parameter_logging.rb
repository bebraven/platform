# Used for filtering out the parameters that you don't want shown in the logs,
# such as passwords or credit card numbers.
#
# Note that I tried writing middleware that uses https://api.rubyonrails.org/classes/ActiveSupport/ParameterFilter.html
# or https://api.rubyonrails.org/classes/ActionDispatch/Http/FilterParameters.html but was struggling to get
# that to work.
unless Rails.env.development?

  Rails.application.config.filter_parameters << lambda do |param_name, value|

    # Note: we have to alter the strings in place because we don't have access to
    # the hash to update the key's value
    if param_name == 'state' || param_name == 'password' || param_name == 'auth'
      value.clear()
      value.insert(0, '[FILTERED]')

    elsif param_name == 'u'
      # HoneycombJsController example:
      # "u"=>"https://platformweb/rise360_module_versions/18?state=[FILTERED]"
      value.gsub!(/state\=([^\&]+)/, 'state=[FILTERED]')

    elsif param_name == 'restiming'
      # HoneycombJsController example:
      # "restiming"=>"{\"https://\":{\"platformweb\":{\"/\":{\"rise360_\":{\"module_versions/18?state=[FILTERED]\":
      # \"6,2b7,2b7,4x,4w,4w,4w,4w,4w,4w,2*127w,1qb\",\"proxy/lessons/sxj0v0dsxa8qykfv36n1citzh6jz/\":
      # {\"index.html?actor=%7B%22name%22%3A%22RISE360_USERNAME_REPLACE%22%2C%20%22mbox%22%3A%5B%22mailto%3ARISE360_PASSWORD_REPLACE%22%5D%7D&
      # auth=[FILTERED]&endpoint=https%3A%2F%2Fplatformweb%2Fdata%2FxAPI\"
      value.gsub!(/auth\=LtiState([^\"\&]+)/, 'auth=[FILTERED]')
      value.gsub!(/state\=([^\"\&]+)/, 'state=[FILTERED]')

    end

  end

  # TODO: this filters the whole redirect path. We just want to filter the state or auth params.
  # Look into monkey patching the filtered_location method here:
  # https://github.com/rails/rails/blob/291a3d2ef29a3842d1156ada7526f4ee60dd2b59/actionpack/lib/action_dispatch/http/filter_redirect.rb#L8

  # Filter logs that say "Redirected to <blah_path>/state=<the_state_value>" as well.
  Rails.application.config.filter_redirect.concat [/state\=([^\&]+)/, /auth\=([^\&]+)/]
end

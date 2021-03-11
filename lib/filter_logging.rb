# frozen_string_literal: true

# Used for filtering out the parameters and data that you don't want shown in the logs,
# such as passwords or credit card numbers or the state param (which is like a password).
class FilterLogging

  def self.is_enabled?
    #(Rails.env.development? ? false : true) # TODO: uncomment me
    true
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
      if param_name == 'state' || param_name == 'password' || param_name == 'auth'
        value.clear()
        value.insert(0, '[FILTERED]')

      elsif param_name == 'u' || param_name == 'pgu'
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

# TODO: take the examples in here and use them to write some specs for the lambda function above
      # https://platformweb/course_project_versions/42/project_submissions/162/edit?state=ZTcxNzM1M2QtZTBhZC00YmE4LTlkOTQtZDExODI0ZTg3MWU1WxMnajYyaGkTupRQPKiP64lXERxQFqckNO0yeeKE8LZQyeuQRy1rO7BGX5y1tfY88hj_UMpQZ37zhwIXhASC9xnEjV8Gy-GqhGGMuHmZkNAVzfzXtNHE-g0bESFJOJpN
    end

    if fields['name'] == 'process_action.action_controller'
      if fields.has_key?('process_action.action_controller.params')
        fields['process_action.action_controller.params'] = parameter_filter.filter_param('restiming', fields['process_action.action_controller.params'])
      end
      if fields.has_key?('process_action.action_controller.path')
        fields['process_action.action_controller.path'] = parameter_filter.filter_param('u', fields['process_action.action_controller.path'])
      end

      # {"action":"send_span","c.e":"km3smjju","c.lb":"km3smpty","c.tti.m":"lt","c.tti.vr":"1474","controller":"honeycomb_js","cpu.cnc":"16","dom.ck":"0","dom.doms":"1","dom.iframe":"0","dom.img":"1","dom.link":"13","dom.link.css":"10","dom.ln":"533","dom.res":"7","dom.script":"13","dom.script.ext":"11","dom.sz":"41234","fetch.bnu":"1","http.initiator":"xhr","http.method":"POST","http.type":"f","javascript.controller":"javascript.project.answer","javascript.project.answer.input.name":"content-name-275a944a-d932-448e-ba0f-f47bc94eb669","javascript.project.answer.input.value":"asfasdf","javascript.project.answer.readonly":"false","javascript.project.answer.response.status":"204","javascript.project.answer.submission.id":"162","javascript.project.answer.url":"/project_submissions/162/project_submission_answers","mem.limit":"4294705152","mem.lsln":"12","mem.lssz":"1879","mem.ssln":"0","mem.sssz":"2","mem.total":"11399460","mem.used":"10646128","mob.dl":"10","mob.etype":"4g","mob.rtt":"50","n":"4","name":"javascript.project.answer.sendAnswer","nocookie":"1","nt_con_end":"1615401981705","nt_con_st":"1615401981705","nt_dns_end":"1615401981705","nt_dns_st":"1615401981705","nt_fet_st":"1615401981705","nt_load_end":"1615401981774","nt_load_st":"1615401981774","nt_req_st":"1615401981733","nt_res_end":"1615401981774","nt_res_st":"1615401981774","nt_ssl_st":"1615401981705","pgu":"https://platformweb/course_project_versions/42/project_submissions/162/edit?state=ZTcxNzM1M2QtZTBhZC00YmE4LTlkOTQtZDExODI0ZTg3MWU1WxMnajYyaGkTupRQPKiP64lXERxQFqckNO0yeeKE8LZQyeuQRy1rO7BGX5y1tfY88hj_UMpQZ37zhwIXhASC9xnEjV8Gy-GqhGGMuHmZkNAVzfzXtNHE-g0bESFJOJpN","pid":"i8hlu1jo","r":"https://braven.instructure.com/","restiming":"{\"https://platformweb/project_submissions/162/project_submission_answers\":\"96ts,1w,1w,r*1,i1\"}","rt.blstart":"1615401973456","rt.bstart":"1615401973493","rt.end":"1615401981774","rt.nstart":"1615401972858","rt.obo":"0","rt.si":"f938fb24-1661-4bf1-9237-ad1ca3d54ecc-qpro51","rt.sl":"4","rt.ss":"1615401972858","rt.start":"manual","rt.tstart":"1615401981705","rt.tt":"1812","sb":"1","scr.bpp":"30/30","scr.dpx":"2","scr.orn":"0/landscape-primary","scr.xy":"1680x1050","sm":"p","state":"[FILTERED]","sv":"12","t_done":"69","t_page":"0","t_resp":"69","trace.serialized":"1;dataset=stagingplatform.bebraven.org,trace_id=ef1a66a7-162d-4153-915e-621d4ccdd452,parent_id=7b0ba367-ef54-4634-b646-242ffab36d47,context=e30=","u":"https://platformweb/project_submissions/162/project_submission_answers","ua.plt":"MacIntel","ua.vnd":"Google Inc.","v":"1.0.0","vis.st":"visible"}
    end

    # Get rid of the value of the state param when querying the LtiLaunch table.
    if fields['name'] == 'sql.active_record' && fields['sql.active_record.name']&.include?('LtiLaunch')
      fields['sql.active_record.type_casted_binds'] = '[FILTERED]'
    end

    fields
  end

end

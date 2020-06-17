class LtiLaunchController < ApplicationController

# TODO: some good examples in this git repo: https://github.com/atomicjolt/lti_starter_app

  # TODO: tmp for testing. We need to get auth actually working.
  skip_before_action :authenticate_user!
  skip_before_action :ensure_admin!

  skip_before_action :verify_authenticity_token

  # Non-standard controller without normal CRUD methods. Disable the convenience module.
  def dry_crud_enabled?
    false
  end

  # hack for PoC. See: https://canvas.instructure.com/doc/api/file.lti_dev_key_config.html
  STATE_PARAM='1234567891' # A random value that Canvas will send back in the final step of auth that we need to ensure matches
  NONCE_PARAM='987654321' # TODO: how to handle this? See this for an example for how to create: https://github.com/Drieam/LtiLauncher/blob/41cd7206daf3d8f1f248738caa0b6bcc098e94a2/app/models/launch.rb#L91

  # This is the OIDC url Canvas is calling in Step 1 here: https://canvas.instructure.com/doc/api/file.lti_dev_key_config.html
  def login
    puts "### lti login called! redirecting to the Canvas authorize_redirect endpoint"
    puts "### request.headers = #{request.headers.env.reject { |key| key.to_s.include?('.') }}"

    # TODO: get / set the state and nonce parameters in the session (note, we may not be able to use session since the callback will come from canvas. need to somehow store the state through this flow though).

# HACK to make this available for deep linking since i can switch b/n Canvas cloud and the local dev env
# TODO: for any caching stuff to work in dev we have to run: bundle exec rails dev:cache
# to make it work in prod, we need to figure it out. The caching config is in the various development/production.rb environment config files.
Rails.cache.write("lti_client_id", params[:client_id])

    # This is the OIDC Authorization end-point in Step 2 of the above linked flow
    redirect_uri='https://platformweb/lti/launch' # Configured as the Redirect URI in the Developer Key
    auth_params = {
      :scope => 'openid',  # OIDC Scope
      :response_type => 'id_token',  # OIDC response is always an id token
      :response_mode => 'form_post',  # OIDC response is always a form post
      :prompt => 'none',  # Don't prompt user on redirect
      :client_id => params[:client_id],
      :redirect_uri => redirect_uri,  # URL to return to after login
      :state => STATE_PARAM,  # State to identify browser session
      :nonce => NONCE_PARAM,  # Prevent replay attacks 
      :login_hint =>  params[:login_hint], # Login hint to identify platform session
      :lti_message_hint => params[:lti_message_hint] # # LTI message hint to identify LTI context within the platform
    }

    # TODO: complete hackery.
    if request.headers['HTTP_REFERER'].include? 'canvascloud'
      redirect_to "http://canvascloud:3030/api/lti/authorize_redirect?#{auth_params.to_query}"
    else
      redirect_to "https://canvas.instructure.com/api/lti/authorize_redirect?#{auth_params.to_query}"
    end
  end

  # TODO: hacking in an endpoint to configure as the Redirect URI in the Developer Key
  def launch
    puts "### lti launch called!" 
    puts "### request.headers = #{request.headers.env.reject { |key| key.to_s.include?('.') }}"
    # TODO: verify the request is coming from Canvas using the public JWK as described in Step 3 here: https://canvas.instructure.com/doc/api/file.lti_dev_key_config.html
    # TODO: decode the id_token which is a signed JWT containing the LTI payload (user identifiers, course contextual data, custom data, etc.).
    puts "### id_token DOES NOT exist, what's up with this request?" unless params[:id_token] 
    puts "### state parameter DOES NOT match, shouldn't show resource" unless params[:state] == @state_param 

    if params[:id_token]
      id_token_segments = params[:id_token].split('.')
      id_token_header = JWT::Base64.url_decode(id_token_segments[0])
      puts "### id_token header = #{id_token_header}"
      id_token_payload = JWT::Base64.url_decode(id_token_segments[1])
      puts "### id_token payload = #{id_token_payload}"
      # This is failing b/c the kid is a timestamp. Not sure what is going on here....
#      decoded_token = Keypair.jwt_decode(params[:id_token])
#      puts "decoded_token = #{decoded_token}"

      require 'json'
      json_payload = JSON.parse(id_token_payload)
      target_link_uri = json_payload["https://purl.imsglobal.org/spec/lti/claim/target_link_uri"]
      custom_fields = json_payload["https://purl.imsglobal.org/spec/lti/claim/custom"]
      deep_link_settings = json_payload["https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings"]

      # Note: can't use session or cookies. These requests come from Canvas, not the users browser. 
      # Hacking this to store the stuff in cache so they are accessible in future calls. Need to actually figure out how to handle this though...
      puts "### reading custom fields: user_id = #{custom_fields['user_id']}, user_email = #{custom_fields['user_email']}, user_fullname = #{custom_fields['user_fullname']}, course_name = #{custom_fields['course_name']},"
      Rails.cache.write("canvas_user_id", custom_fields["user_id"])
      Rails.cache.write("canvas_email", custom_fields["user_email"])
      Rails.cache.write("canvas_fullname", custom_fields["user_fullname"])
      Rails.cache.write("canvas_course_name", custom_fields["course_name"])

      # THis is all hacky just to store whatever the last lti launch had for params
      Rails.cache.write("lti_deployment_id", json_payload["https://purl.imsglobal.org/spec/lti/claim/deployment_id"])
      Rails.cache.write("lti_deep_link_return_url", deep_link_settings["deep_link_return_url"]) if deep_link_settings
      Rails.cache.write("lti_deep_link_jwt_response", deep_link_response) if deep_link_settings

      puts "### set custom fields in the cache to:"
      @canvas_user_id = Rails.cache.fetch("canvas_user_id")
      @canvas_email = Rails.cache.fetch("canvas_email")
      @canvas_fullname = Rails.cache.fetch("canvas_fullname")
      @canvas_course_name = Rails.cache.fetch("canvas_course_name")
      puts "### in lti/launch: canvas_user_id = #{@canvas_user_id}, @canvas_email = #{@canvas_email}, @canvas_fullname = #{@canvas_fullname}, @canvas_course_name = #{@canvas_course_name}"

      redirect_to target_link_uri
    elsif params[:target_link_uri]
      redirect_to params[:target_link_uri] # This happens when I try to edit an assignment and choose an external tool (not Assignment Edit isn't a configured placement when I was trying)
    else
      puts "since we don't have an id_token or target_link_uri param, just sending to the LTI PoC url for now until we can figure out whats going on"
      redirect_to '/lti_poc'
    end
  end

  # TODO: complete hackery to allow the form to submit back a DeepLinkingResponse to canvas
  def deep_link_response
    #token = decoded_jwt_token(request)
    #platform_iss = token["iss"]
    #application_instance = current_application_instance
    #client_id = application_instance.application.client_id(platform_iss)

#    client_id = '160050000000000011'
    client_id = Rails.cache.fetch("lti_client_id")
    platform_iss = 'https://canvas.instructure.com'

    payload = {
      iss: client_id, # A unique identifier for the entity that issued the JWT
      aud: platform_iss, # Authorization server identifier
      iat: Time.now.to_i, # Timestamp for when the JWT was created
      exp: Time.now.to_i + 300, # Timestamp for when the JWT should be treated as having expired
      # (after allowing a margin for clock skew)
      azp: client_id,
      nonce: SecureRandom.hex(10),
      "https://purl.imsglobal.org/spec/lti/claim/message_type" => "LtiDeepLinkingResponse",
      "https://purl.imsglobal.org/spec/lti/claim/version" => "1.3.0",
      "https://purl.imsglobal.org/spec/lti/claim/deployment_id" => Rails.cache.fetch("lti_deployment_id"),
      "https://purl.imsglobal.org/spec/lti-dl/claim/content_items" => content_items,
    }

#    if token["data"].present?
#      payload[LtiAdvantage::Definitions::DEEP_LINKING_DATA_CLAIM] = token["data"]
#    end

    jwt =  sign_tool_jwt(payload)
    jwt

#    render json: {
#      jwt: jwt,
#    }
  end

  def sign_tool_jwt(payload)
    # TODO: need to implement this.
    #jwk = jwk.create!
    #JWT.encode(payload, jwk.private_key, jwk.alg, kid: jwk.kid, typ: "JWT")
    Keypair.create!
    Keypair.jwt_encode(payload)
  end

  # TODO: complete hackery. Just changing these hardcoded responses to see what happens back in Canvas after deep linking.
  def content_items
    out = []

# trying out some various HTML responses to see how they get iframed. This is not deep linking stuff..
    # Note: If the HTML fragment renders a a single resource which is also addressable directly, the tool SHOULD use the link type with an embed code.
#    out << {
#        "type" => "html",
#        "html" => '<h1>Braven Deep Linked Resource</h1><iframe style="width: 100%; height: 100%;" src="https://stagingportal.bebraven.org/courses/58/assignments/1312" allowfullscreen></iframe>'
#        "html" => '<h1>Braven Deep Linked Resource</h1><br/><iframe style="width: 100%; height: 100%;" src="https://platformweb/course_contents/new" allowfullscreen></iframe>'
#        "html" => File.read("tmp.html")
#    }

# normal link, not a deeplink?
#    out << {
#        "type" => "link",
#        "url" => "https://stagingportal.bebraven.org/courses/58/assignments/1312",
#        "iframe" => { 
#          "width" => 1000,
#          "height" => 1000,
#          "src" => "https://stagingportal.bebraven.org/courses/58/assignments/1312"
#        }
#    }

# deep link?
# See " 2.2 LTI Resource Link" of https://www.imsglobal.org/spec/lti-dl/v2p0#link for more options
    out << {
        "type" => "ltiResourceLink",
        "url" => "https://stagingportal.bebraven.org/courses/58/assignments/1312",
        "iframe" => { 
          "width" => 1000,
          "height" => 1000
        }
    }
    out
  end

end

# Needed to use the url_helpers outside of views and controller
Rails.application.routes.default_url_options[:host] = Rails.application.secrets.application_host

Rails.application.routes.draw do

  resources :course_resources

  resources :custom_contents do
    post :publish
    resources :custom_content_versions, path: 'versions', only: [:index, :show]
  end

  # Support public-facing legacy endpoints to course_contents
  get 'course_contents/:id', to: 'custom_contents#show'
  get 'course_contents/:custom_content_id/versions', to: 'custom_content_versions#index'
  get 'course_contents/:custom_content_id/versions/:id', to: 'custom_content_versions#show'

  resources :file_upload, only: [:create]

  devise_for :users, controllers: { registrations: 'users/registrations', confirmations: 'users/confirmations', passwords: 'users/passwords' }

  devise_scope :user do
    get 'users/password/check_email', to: "users/passwords#check_email"
    get 'users/registration', to: "users/registrations#show"
    post '/admin/users', to: 'users#create'
  end

  get 'home/welcome'

  resources :base_courses, only: [:index], path: 'course_management'
  get 'course_management/launch', to: 'base_courses#launch_new'
  post 'course_management/launch', to: 'base_courses#launch_create'
  resources :courses, controller: 'base_courses', type: 'Course'
  resources :course_templates, controller: 'base_courses', type: 'CourseTemplate'

  # See this for why we nest things only 1 deep:
  # http://weblog.jamisbuck.org/2007/2/5/nesting-resources

  resources :courses, only: [:index, :show] do
    resources :grade_categories, only: [:index, :show]
    resources :projects, only: [:index, :show]
    resources :lessons, only: [:index, :show]
  end

  resources :grade_categories, only: [:index, :show] do
    resources :projects, only: [:index, :show]
    resources :lessons, only: [:index, :show]
  end

  resources :base_course_custom_content_versions, only: [:create] do
    resources :project_submissions, :path => 'submissions', only: [:show, :new, :create]
  end

  resources :project_submissions, only: [:show]

  resources :lessons, only: [:index, :show] do
    resources :lesson_submissions, only: [:index, :show], :path => 'submissions'
    resources :lesson_contents, only: [:new, :show, :create], :path => 'contents'
  end

  resources :lesson_contents, only: [:new, :show, :create]

  resources :access_tokens, except: [:show]

  # Exposes the public JWK so that external services can encode payloads using it and we
  # can decode them using our private key. E.g. JWK authentication flows.
  resources :keypairs, only: :index, format: :j, path: 'public_jwk'

  root to: "home#welcome"

  resources :users do
    member do
      post 'confirm' => 'users#confirm'
    end
  end

  # Sync to LMS
  post 'sync_to_lms', to: 'salesforce#sync_to_lms'
  get 'sync_to_lms', to: 'salesforce#init_sync_to_lms'
  # Sync to Join
  post 'sync_to_join', to: 'join#sync_to_join'
  get 'sync_to_join', to: 'join#init_sync_to_join'

  # Zoom Management
  get 'sync_to_webinar', to: 'webinar#init_sync_to_webinar'
  post 'sync_to_webinar', to: 'webinar#sync_to_webinar'

  # Generate Webinar
  get 'generate_webinar', to: 'webinar#init_generate_webinar'
  post 'generate_webinar', to: 'webinar#generate_webinar'

  # Slack Management
  get 'sync_to_slack', to: 'slack#init_sync_to_slack'
  post 'sync_to_slack', to: 'slack#sync_to_slack'

  # Booster Slack Management
  get 'sync_to_booster_slack', to: 'slack#init_sync_to_booster_slack'
  post 'sync_to_booster_slack', to: 'slack#sync_to_booster_slack'

  # RubyCAS Routes
  resources :cas, except: [:show]
  get '/cas/login', to: 'cas#login'
  post '/cas/login', to: 'cas#loginpost'
  get '/cas/logout', to: 'cas#logout'
  get '/cas/loginTicket', to: 'cas#loginTicket'
  post '/cas/loginTicket', to: 'cas#loginTicketPost'
  get '/cas/validate', to: 'cas#validate'
  get '/cas/serviceValidate', to: 'cas#serviceValidate'
  get '/cas/proxyValidate', to: 'cas#proxyValidate'
  get '/cas/proxy', to: 'cas#proxy'

  # LinkedIn authorization routes
  get '/linked_in/login' => 'linked_in_authorization#login'
  get '/linked_in/auth' => 'linked_in_authorization#launch'
  get '/linked_in/auth_redirect' => 'linked_in_authorization#oauth_redirect'

  # LTI Extension Routes
  post '/lti/login', to: 'lti_launch#login'
  post '/lti/launch', to: 'lti_launch#launch'

  get '/lti/assignment_selection/new', to: 'lti_assignment_selection#new'     # https://canvas.instructure.com/doc/api/file.assignment_selection_placement.html

  get '/lti/link_selection/new', to: 'lesson_contents#new' # https://canvas.instructure.com/doc/api/file.link_selection_placement.html
  post '/lti/link_selection', to: 'lesson_contents#create' # https://canvas.instructure.com/doc/api/file.link_selection_placement.html

  get '/lti/course_resources', to: 'course_resources#lti_show'

  # Proxy xAPI messages to the LRS.
  match '/data/xAPI/*endpoint', to: 'lrs_xapi_proxy#xAPI', via: [:get, :put]

  # There is a route similar to the commented out one below that doesn't show up here. See 'lib/lti_rise360_proxy.rb' and 'config/application.rb'
  # match '/rise360_proxy/*endpoint', to: AWS_S3

  # Braven Network endpoints
  get '/network/connect', to: 'network#connect'
  get '/network/join', to: 'network#join'
  post '/network/create_champion', to: 'network#create_champion'

  # Honeycomb Instrumentation Routes
  post '/honeycomb_js/send_span', to: 'honeycomb_js#send_span'
end

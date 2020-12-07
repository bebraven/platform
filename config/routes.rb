# Needed to use the url_helpers outside of views and controller
Rails.application.routes.default_url_options[:host] = Rails.application.secrets.application_host 

Rails.application.routes.draw do

  resources :course_resources

  resources :rise360_modules, only: [:show, :new, :create]

  resources :custom_contents do
    resources :custom_content_versions, path: 'versions', only: [:index, :show]
  end

  resources :projects, controller: "custom_contents", type: "Project" do
    resources :project_versions, path: 'versions', controller: 'custom_content_versions', type: "ProjectVersion", only: [:index, :show]
  end

  resources :surveys, controller: "custom_contents", type: "Survey" do
    resources :survey_versions, path: 'versions', controller: 'custom_content_versions', type: "SurveyVersion", only: [:index, :show]
  end

  resources :file_upload, only: [:create]

  devise_for :users, controllers: { registrations: 'users/registrations', confirmations: 'users/confirmations', passwords: 'users/passwords' }

  devise_scope :user do
    get 'users/password/check_email', to: "users/passwords#check_email"
    get 'users/registration', to: "users/registrations#show"
    post '/admin/users', to: 'users#create'
  end

  get 'home/welcome'

  # See this for why we nest things only 1 deep:
  # http://weblog.jamisbuck.org/2007/2/5/nesting-resources

  resources :courses do

    collection do
      get :launch, to: 'courses#launch_new'
      post :launch, to: 'courses#launch_create'
    end

    resources :course_project_versions, controller: 'course_custom_content_versions', type: 'CourseProjectVersion', only: [:new]
    resources :course_survey_versions, controller: 'course_custom_content_versions', type: 'CourseSurveyVersion', only: [:new]

    resources :peer_review_submissions, only: [:new, :create]

    resources :waivers, only: [] do
      collection do
        post :publish
        delete :unpublish
      end
    end

    resources :peer_reviews, only: [] do
      collection do
        post :publish
        delete :unpublish
      end
    end
  end

  resources :course_custom_content_versions, only: [:create, :update, :destroy] 

  resources :course_project_versions, controller: 'course_custom_content_versions', type: 'CourseProjectVersion', only: [] do
    resources :project_submissions, only: [:new, :edit, :create, :update]
    resources :project_submission_answers, only: [:index, :create]
  end

  resources :course_survey_versions, controller: 'course_custom_content_versions', type: 'CourseSurveyVersion', only: [] do
    resources :survey_submissions, only: [:new, :create]
  end

  resources :courses, only: [:index, :show] do
    resources :grade_categories, only: [:index, :show]
    resources :projects, only: [:index, :show]
    resources :lessons, only: [:index, :show]
  end

  resources :grade_categories, only: [:index, :show] do
    resources :projects, only: [:index, :show]
    resources :lessons, only: [:index, :show]
  end

  resources :project_submissions, only: [:show]
  resources :survey_submissions, only: [:show]
  resources :peer_review_submissions, only: [:show]

  resources :lessons, only: [:index, :show] do
    resources :lesson_submissions, only: [:index, :show], :path => 'submissions'
  end

  resources :waiver_submissions, only: [:new, :create] do
    collection do 
      get :launch
      get :completed
    end
  end

  resources :access_tokens, except: [:show]

  # Exposes the public JWK so that external services can encode payloads using it and we
  # can decode them using our private key. E.g. JWK authentication flows.
  resources :keypairs, only: :index, format: :j, path: 'public_jwk'

  root to: "home#welcome"

  resources :users do
    member do
      post 'confirm' => 'users#confirm'
    end

    resources :users_roles, only: [:new, :create, :destroy]
  end

  # Sync to LMS
  post 'sync_to_lms', to: 'salesforce#sync_to_lms'
  get 'sync_to_lms', to: 'salesforce#init_sync_to_lms'
  # Sync to Join
  post 'sync_to_join', to: 'join#sync_to_join'
  get 'sync_to_join', to: 'join#init_sync_to_join'

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

  get '/lti/link_selection/new', to: 'rise360_modules#new' # https://canvas.instructure.com/doc/api/file.link_selection_placement.html
  post '/lti/link_selection', to: 'rise360_modules#create' # https://canvas.instructure.com/doc/api/file.link_selection_placement.html

  get '/lti/course_resources', to: 'course_resources#lti_show'

  # Send xAPI messages to our mock LRS.
  match '/data/xAPI/*endpoint', to: 'lrs_xapi_mock#xAPI', via: [:get, :put]

  # There is a route similar to the commented out one below that doesn't show up here. See 'lib/lti_rise360_proxy.rb' and 'config/application.rb'
  # match '/rise360_proxy/*endpoint', to: AWS_S3

  # Honeycomb Instrumentation Routes
  post '/honeycomb_js/send_span', to: 'honeycomb_js#send_span'
end

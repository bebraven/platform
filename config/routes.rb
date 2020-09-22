# Needed to use the url_helpers outside of views and controller
Rails.application.routes.default_url_options[:host] = Rails.application.secrets.application_host 

Rails.application.routes.draw do

  resources :course_resources

  resources :course_contents do
    post :publish
    resources :course_content_histories, path: 'versions', only: [:index, :show]
  end
  resources :file_upload, only: [:create]

  devise_for :users, controllers: { registrations: 'users/registrations', confirmations: 'users/confirmations', passwords: 'users/passwords' }

  devise_scope :user do
    get 'users/password/check_email', to: "users/passwords#check_email"
    get 'users/registration', to: "users/registrations#show"
  end

  get 'home/welcome'

  resources :industries, except: [:show]
  resources :interests, except: [:show]
  resources :locations, only: [:index, :show]
  resources :majors, except: [:show]

  resources :base_courses, only: [:index], path: 'course_management'
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

  resources :projects, only: [:index, :show] do
    resources :project_submissions, :path => 'submissions', only: [:create]
  end

  resources :lessons, only: [:index, :show] do
    resources :lesson_submissions, only: [:index, :show], :path => 'submissions'
    resources :lesson_contents, only: [:new, :show, :create], :path => 'contents'
  end

  resources :lesson_contents, only: [:new, :show, :create]
  resources :roles, except: [:show]
  resources :users, only: [:index, :show]

  resources :waivers, only: [:new, :create] do
    collection do
      get :launch
    end
  end

  resources :postal_codes, only: [:index, :show] do
    collection do
      get :distance
      post :search
    end
  end

  resources :access_tokens, except: [:show]

  # Exposes the public JWK so that external services can encode payloads using it and we
  # can decode them using our private key. E.g. JWK authentication flows.
  resources :keypairs, only: :index, format: :j, path: 'public_jwk'

  resources :validations, only: [:index] do
    collection do
      get :report
    end
  end

  root to: "home#welcome"

  # Admin stuff
  namespace :admin do
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
  end

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

  # LTI Extension Routes
  post '/lti/login', to: 'lti_launch#login'
  post '/lti/launch', to: 'lti_launch#launch'

  get '/lti/assignment_selection/new', to: 'lti_assignment_selection#new'     # https://canvas.instructure.com/doc/api/file.assignment_selection_placement.html
  post '/lti/assignment_selection', to: 'lti_assignment_selection#create'     # https://canvas.instructure.com/doc/api/file.assignment_selection_placement.html

  get '/lti/link_selection/new', to: 'lesson_contents#new' # https://canvas.instructure.com/doc/api/file.link_selection_placement.html
  post '/lti/link_selection', to: 'lesson_contents#create' # https://canvas.instructure.com/doc/api/file.link_selection_placement.html

  get '/lti/course_resources', to: 'course_resources#lti_show'

  # Proxy xAPI messages to the LRS.
  match '/data/xAPI/*endpoint', to: 'lrs_xapi_proxy#xAPI', via: [:get, :put]

  # There is a route similar to the commented out one below that doesn't show up here. See 'lib/lti_rise360_proxy.rb' and 'config/application.rb'
  # match '/rise360_proxy/*endpoint', to: AWS_S3

  # Honeycomb Instrumentation Routes
  post '/honeycomb_js/send_span', to: 'honeycomb_js#send_span'
end

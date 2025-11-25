Rails.application.routes.draw do
  root 'pages#index'

  # Accounts
  resources :accounts, param: :aid

  # Posts
  resources :posts, param: :aid

  # Images
  resources :images, param: :aid do
    member do
      post "variants_create" => "images#variants_create", as: "variants_create"
      delete "variants_destroy" => "images#variants_destroy", as: "variants_destroy"
    end
  end

  # Emojis
  resources :emojis, param: :aid do
    collection do
      get :picker
    end
  end

  # Reactions
  post 'reactions/react' => 'reactions#react', as: :react

  # Diffuses
  post 'diffuses/create' => 'diffuses#create', as: :diffuse
  delete 'diffuses/destroy' => 'diffuses#destroy', as: :undiffuse

  # Sessions
  get 'sessions/start'
  delete 'signout' => 'sessions#signout'
  resources :sessions, except: [:new, :create], param: :aid

  # Signup
  get 'signup' => 'signup#new'
  post 'signup' => 'signup#create'

  # OAuth
  post 'oauth/start' => 'oauth#start'
  get 'oauth/callback' => 'oauth#callback'
  post 'oauth/fetch' => 'oauth#fetch'

  # API v1
  namespace :v1 do
    root 'pages#index'

    # Pages
    get 'start' => 'pages#start'

    # Accounts
    post 'accounts' => 'accounts#show'
    resources :accounts, only: [], param: :aid do
      resource :follow, only: [:create, :destroy]
    end

    # Posts
    resources :posts, only: [:show, :create], param: :aid do
      # member do
      #   post 'show' => 'posts#show'
      # end
      resource :reaction, only: [:create, :destroy]
      resource :diffuse, only: [:create, :destroy]
    end

    # Emojis
    post 'emojis/groups' => 'emojis#groups_index'
    post 'emojis/groups/:group_name' => 'emojis#groups_show'
    post 'emojis/:aid' => 'emojis#show'

    # Search
    post 'search' => 'search#index'

    # Feeds
    post 'feeds/index' => 'feeds#index'
    post 'feeds/follow' => 'feeds#follow'
    post 'feeds/current' => 'feeds#current'
    post 'feeds/account' => 'feeds#account'

    # Sessions
    delete 'signout' => 'sessions#signout'

    # Signup
    post 'signup' => 'signup#create'

    # Settings
    post 'settings/account' => 'settings#post_account'

    # OAuth
    post 'oauth/start' => 'oauth#start'
    post 'oauth/callback' => 'oauth#callback'
    post 'oauth/fetch' => 'oauth#fetch'
  end

  # Others
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Errors
  match '*path', to: 'application#routing_error', via: :all
end

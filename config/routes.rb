Rails.application.routes.draw do
  mount MissionControl::Jobs::Engine, at: "/jobs"
  root 'pages#index'

  # ActivityPub
  scope module: 'activity_pub' do
    get '.well-known/webfinger', to: 'well_known/webfinger#show'
    get '.well-known/nodeinfo', to: 'well_known/nodeinfo#index'
    get '.well-known/host-meta', to: 'well_known/host_meta#show'
    get 'nodeinfo/2.1', to: 'well_known/nodeinfo#show', as: 'nodeinfo_2_1'

    post 'inbox', to: 'inboxes#create'

    resources :accounts, only: [:show], param: :aid do
      member do
        post 'inbox', to: 'inboxes#create'
        get 'outbox', to: 'outboxes#show'
        get 'followers', to: 'followers#index'
        get 'following', to: 'following#index'
        get 'collections/featured', to: 'collections#featured'
      end

      resources :posts, only: [:show], param: :aid
    end
  end

  # Accounts
  get '/@:name_id', to: 'accounts#show', constraints: { name_id: /.*/ }, as: :profile_viewer

  # Posts
  # resources :posts, param: :aid

  # Images
  resources :images, param: :aid do
    member do
      post "create_variant" => "images#create_variant", as: "create_variant"
      delete "delete_variant" => "images#delete_variant", as: "delete_variant"
      delete "delete_original" => "images#delete_original", as: "delete_original"
    end
  end

  # Videos
  resources :videos, param: :aid do
    member do
      post "create_variant" => "videos#create_variant", as: "create_variant"
      delete "delete_variant" => "videos#delete_variant", as: "delete_variant"
      delete "delete_original" => "videos#delete_original", as: "delete_original"
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

  # Trends
  resources :trends, only: [:index, :create]

  # Notifications
  resources :notifications, only: [:new, :create]

  # OG
  get 'og/posts/:aid' => 'og_images#post', as: :og_post
  # get 'og/accounts/:aid' => 'og_images#account', as: :og_account

  # API v1
  namespace :v1 do
    root 'pages#index'

    # Pages
    get 'start' => 'pages#start'

    # Accounts
    post 'accounts/:name_id' => 'accounts#show'
    resources :accounts, only: [], param: :aid do
      resource :follow, only: [:create, :destroy]
    end

    # Posts
    post 'posts/:aid' => 'posts#show'
    resources :posts, only: [:create, :destroy], param: :aid do
      resource :reaction, only: [:create, :destroy]
      resource :diffuse, only: [:create, :destroy]
      post 'quotes'
      post 'diffusions'
      post 'reactions'
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

    # Notifications
    post 'notifications' => 'notifications#index'
    post 'notifications/unread_count' => 'notifications#unread_count'

    # WebPush Subscriptions
    post 'webpush_subscriptions' => 'webpush_subscriptions#create'

    # Sessions
    delete 'signout' => 'sessions#signout'

    # Signup
    post 'signup' => 'signup#create'

    # Settings
    post 'settings/account' => 'settings#account'
    post 'settings/notification' => 'settings#notification'
    post 'settings/update_notification' => 'settings#update_notification'
    delete 'settings/leave' => 'settings#leave'

    # OAuth
    post 'oauth/start' => 'oauth#start'
    post 'oauth/callback' => 'oauth#callback'
    post 'oauth/fetch' => 'oauth#fetch'

    # Trends
    post 'trends' => 'trends#index'
  end

  # Others
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Errors
  match '*path', to: 'application#routing_error', via: :all
end

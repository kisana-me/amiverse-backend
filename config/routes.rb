Rails.application.routes.draw do
  root 'pages#index'

  # Accounts
  resources :accounts, param: :aid

  # Posts
  resources :posts, param: :aid

  # Images
  resources :images, only: [:new, :create], param: :aid

  # Emojis
  resources :emojis, param: :aid

  # Reactions
  post 'reactions/react' => 'reactions#react', as: :react

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
    resources :accounts, param: :aid
    resources :posts, param: :aid
  end

  # Others
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Errors
  match '*path', to: 'application#routing_error', via: :all
end

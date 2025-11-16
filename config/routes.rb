Rails.application.routes.draw do
  root "pages#index"

  resources :accounts

  # Others
  get "up" => "rails/health#show", as: :rails_health_check

  # Errors
  match "*path", to: "application#routing_error", via: :all
end

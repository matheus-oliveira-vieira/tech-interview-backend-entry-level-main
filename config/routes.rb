require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'
  resources :products
  post '/cart', to: 'carts#create'
  get '/cart', to: 'carts#show'
  put '/cart/add_item', to: 'carts#update'
  delete '/cart/:product_id', to: 'carts#destroy'
  get "up" => "rails/health#show", as: :rails_health_check

  root "rails/health#show"
end

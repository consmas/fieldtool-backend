Rails.application.routes.draw do
  devise_for :users, defaults: { format: :json }, controllers: { sessions: "auth/sessions" }, skip: [:registrations]
  devise_scope :user do
    post "auth/login", to: "auth/sessions#create"
    delete "auth/logout", to: "auth/sessions#destroy"
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  scope defaults: { format: :json } do
    resources :users, only: [:index, :show, :create, :update, :destroy]
    resources :vehicles, only: [:index, :show, :create, :update, :destroy]
    resources :trips, only: [:index, :show, :create, :update, :destroy] do
      member do
        post "status", to: "trips/status#create"
        post "odometer/start", to: "trips/odometer#start"
        post "odometer/end", to: "trips/odometer#end"
      end
      resource :pre_trip, only: [:show, :create, :update], controller: "trips/pre_trips"
      resources :stops, only: [:index, :show, :create, :update, :destroy], controller: "trips/stops"
      resources :locations, only: [:create], controller: "trips/locations" do
        collection do
          get "latest"
        end
      end
      resources :evidence, only: [:create], controller: "trips/evidence"
    end
  end
end

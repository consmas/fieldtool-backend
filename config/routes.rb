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
    resources :destinations, only: [:index, :show, :create, :update, :destroy] do
      member do
        post "calculate"
      end
    end
    resources :fuel_prices, only: [:index, :create]
    get "chat/inbox", to: "chats/inboxes#index"
    resources :users, only: [:index, :show, :create, :update, :destroy]
    resources :vehicles, only: [:index, :show, :create, :update, :destroy]
    resources :trips, only: [:index, :show, :create, :update, :destroy] do
      member do
        post "status", to: "trips/status#create"
        post "odometer/start", to: "trips/odometer#start"
        post "odometer/end", to: "trips/odometer#end"
      end
      resource :pre_trip, only: [:show, :create, :update], controller: "trips/pre_trips"
      patch "pre_trip/verify", to: "trips/pre_trip_verifications#update"
      patch "pre_trip/confirm", to: "trips/pre_trip_verifications#confirm"
      patch "fuel_allocation", to: "trips/fuel_allocations#update"
      patch "road_expense", to: "trips/road_expenses#update"
      patch "road_expense/receipt", to: "trips/road_expenses#receipt"
      resources :stops, only: [:index, :show, :create, :update, :destroy], controller: "trips/stops"
      resources :locations, only: [:create], controller: "trips/locations" do
        collection do
          get "latest"
        end
      end
      resources :evidence, only: [:create], controller: "trips/evidence"
      resource :attachments, only: [:update], controller: "trips/attachments"
      resource :chat, only: [:show], controller: "trips/chats"
      resources :chat_messages, only: [:create, :update], path: "chat/messages", controller: "trips/chat_messages"
    end
  end
end

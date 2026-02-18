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
    resources :expenses, only: [:index, :create, :update, :destroy] do
      collection do
        get :summary
        post "bulk/approve", to: "expenses/bulk#approve"
        post "bulk/reject", to: "expenses/bulk#reject"
        post "bulk/mark-paid", to: "expenses/bulk#mark_paid"
        post "automation/road-fee/sync", to: "expenses/automation#road_fee_sync"
        post "fuel/recalculate", to: "expenses/automation#fuel_recalculate"
      end

      member do
        post :submit, to: "expenses/workflows#submit"
        post :approve, to: "expenses/workflows#approve"
        post :reject, to: "expenses/workflows#reject"
        post "mark-paid", to: "expenses/workflows#mark_paid"
      end
    end
    get "chat/inbox", to: "chats/inboxes#index"
    namespace :chat, module: "chats", as: "chat" do
      resources :conversations, only: [:index, :create, :show] do
        member do
          patch :read, to: "conversations#mark_read"
        end
        resources :messages, only: [:create], controller: "conversation_messages"
      end
    end
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

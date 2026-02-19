require "sidekiq/web"

Rails.application.routes.draw do
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    env_user = ENV["SIDEKIQ_ADMIN_USER"].to_s
    env_pass = ENV["SIDEKIQ_ADMIN_PASSWORD"].to_s
    next false if env_user.blank? || env_pass.blank?

    ActiveSupport::SecurityUtils.secure_compare(username.to_s, env_user) &
      ActiveSupport::SecurityUtils.secure_compare(password.to_s, env_pass)
  end

  mount Sidekiq::Web => "/admin/sidekiq"
  get "/admin/sidekiq-dashboard", to: "admin/sidekiq_dashboard#show"
  post "/admin/sidekiq-dashboard/job-action", to: "admin/sidekiq_dashboard#job_action"
  post "/admin/sidekiq-dashboard/queue-action", to: "admin/sidekiq_dashboard#queue_action"
  post "/admin/sidekiq-dashboard/process-action", to: "admin/sidekiq_dashboard#process_control"

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
    namespace :reports, module: "reports", as: "reports" do
      get :overview, to: "dashboard#overview"
      get :trips, to: "dashboard#trips"
      get :expenses, to: "dashboard#expenses"
      get :drivers, to: "dashboard#drivers"
      get :vehicles, to: "dashboard#vehicles"
    end
    namespace :api do
      namespace :v1 do
        namespace :webhooks, module: "webhooks" do
          resources :subscriptions, only: [:index, :show, :create, :update, :destroy] do
            member do
              post :test
            end
          end
          resources :deliveries, only: [:index] do
            member do
              post :retry
            end
          end
          post "test_receiver", to: "test_receiver#create"
        end

        namespace :admin, module: "admin" do
          get "webhooks/stats", to: "webhooks#stats"
          get "webhooks/subscriptions", to: "webhooks#subscriptions"
          patch "webhooks/subscriptions/:id/reactivate", to: "webhooks#reactivate"
          get "sidekiq/dashboard", to: "sidekiq_dashboard#show"
        end
      end
    end

    namespace :admin do
      get "sidekiq/health", to: "sidekiq_health#show"
    end
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

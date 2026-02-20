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
    get "maintenance/my_vehicle", to: "maintenance/driver#my_vehicle"
    get "maintenance/snapshot", to: "maintenance/driver#snapshot"
    get "drivers/me/maintenance", to: "maintenance/driver#driver_maintenance"
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
        namespace :client, module: "client" do
          post "auth/login", to: "auth#login"
          post "auth/logout", to: "auth#logout"
          post "auth/forgot_password", to: "auth#forgot_password"
          post "auth/reset_password", to: "auth#reset_password"

          get "dashboard", to: "dashboard#show"
          get "shipments", to: "shipments#index"
          get "shipments/:tracking_number", to: "shipments#show"
          get "shipments/:tracking_number/track", to: "shipments#track"
          get "shipments/:tracking_number/events", to: "shipments#events"
          get "shipments/:tracking_number/pod", to: "shipments#pod"
          post "shipments/:tracking_number/feedback", to: "shipments#feedback"

          get "invoices", to: "invoices#index"
          get "invoices/:invoice_number", to: "invoices#show"
          get "invoices/:invoice_number/pdf", to: "invoices#pdf"
          get "billing/summary", to: "invoices#summary"

          get "profile", to: "profile#show"
          patch "profile", to: "profile#update"
          patch "profile/password", to: "profile#password"
        end
        get "track/:tracking_link_token", to: "/api/v1/public_tracking#show"

        namespace :admin, module: "admin" do
          get "webhooks/stats", to: "webhooks#stats"
          get "webhooks/subscriptions", to: "webhooks#subscriptions"
          patch "webhooks/subscriptions/:id/reactivate", to: "webhooks#reactivate"
          get "sidekiq/dashboard", to: "sidekiq_dashboard#show"
        end
        resources :notifications, only: [:index, :destroy], controller: "/notifications" do
          collection do
            get :unread_count, to: "/notifications#unread_count"
            post :mark_all_read, to: "/notifications#mark_all_read"
          end
          member do
            patch :read, to: "/notifications#mark_read"
            patch :archive, to: "/notifications#archive"
          end
        end
        get "notifications/preferences", to: "/notification_preferences#index"
        put "notifications/preferences", to: "/notification_preferences#update"
        put "notifications/preferences/quiet_hours", to: "/notification_preferences#quiet_hours"
        post "devices", to: "/devices#create"
        delete "devices/:token", to: "/devices#destroy"
        resources :drivers, only: [:index, :show, :update], controller: "/drivers" do
          member do
            get "scores", to: "/driver_scores#index"
            get "scores/current", to: "/driver_scores#current"
            get "badges", to: "/driver_scores#badges"
          end
          collection do
            get "leaderboard", to: "/drivers#leaderboard"
          end
        end
        get "drivers/:driver_id/documents", to: "/driver_documents#index"
        post "drivers/:driver_id/documents", to: "/driver_documents#create"
        patch "drivers/:driver_id/documents/:id", to: "/driver_documents#update"
        patch "drivers/:driver_id/documents/:id/verify", to: "/driver_documents#verify"
        get "drivers/documents/expiring", to: "/driver_documents#expiring"
        get "drivers/documents/compliance_summary", to: "/driver_documents#compliance_summary"
        get "me/profile", to: "/me#profile"
        get "me/documents", to: "/me#documents"
        post "me/documents", to: "/me#create_document"
        get "me/scores", to: "/me#scores"
        get "me/badges", to: "/me#badges"
        get "me/rank", to: "/me#rank"
        get "me/improvement_tips", to: "/me#improvement_tips"
        get "admin/scoring_config", to: "/admin/scoring_config#show"
        patch "admin/scoring_config", to: "/admin/scoring_config#update"
        get "vehicles/:vehicle_id/fuel_logs", to: "/fuel_logs#index"
        post "vehicles/:vehicle_id/fuel_logs", to: "/fuel_logs#create_for_vehicle"
        post "trips/:trip_id/fuel_logs", to: "/fuel_logs#create_for_trip"
        get "fuel_logs", to: "/fuel_logs#index"
        get "fuel/analysis", to: "/fuel/analysis#index"
        get "fuel/anomalies", to: "/fuel/analysis#anomalies"
        patch "fuel/analysis/:id/investigate", to: "/fuel/analysis#investigate"
        get "fuel/analysis/vehicle/:vehicle_id", to: "/fuel/analysis#vehicle"
        get "fuel/analysis/driver/:driver_id", to: "/fuel/analysis#driver"

        resources :work_orders, only: [:index, :show, :create, :update], controller: "/work_orders" do
          member do
            patch :status, to: "/work_orders#update_status"
          end
          collection do
            get :summary, to: "/work_orders#summary"
          end

          resources :parts, only: [:create, :update, :destroy], controller: "/work_orders/parts"
          resources :comments, only: [:index, :create], controller: "/work_orders/comments"
        end

        get "vehicles/:vehicle_id/work_orders", to: "/work_orders#by_vehicle"
        get "maintenance_schedules", to: "/maintenance_schedules#index"
        post "maintenance_schedules", to: "/maintenance_schedules#create"
        get "vehicles/:vehicle_id/maintenance_schedules", to: "/maintenance_schedules#index"
        post "vehicles/:vehicle_id/maintenance_schedules", to: "/maintenance_schedules#create"
        patch "maintenance_schedules/:id", to: "/maintenance_schedules#update"
        delete "maintenance_schedules/:id", to: "/maintenance_schedules#destroy"
        get "maintenance/due", to: "/maintenance_schedules#due"
        get "maintenance_schedules/templates", to: "/maintenance_schedules#templates"
        post "maintenance_schedules/templates", to: "/maintenance_schedules#apply_template"

        resources :maintenance_vendors, only: [:index, :show, :create, :update], path: "maintenance/vendors", controller: "/maintenance/vendors"

        get "vehicles/:vehicle_id/documents", to: "/vehicle_documents#index"
        post "vehicles/:vehicle_id/documents", to: "/vehicle_documents#create"
        patch "vehicles/:vehicle_id/documents/:id", to: "/vehicle_documents#update"
        get "documents/expiring", to: "/vehicle_documents#expiring"

        get "reports/maintenance", to: "/reports/maintenance#index"
        get "reports/vehicles/:id/maintenance_history", to: "/reports/maintenance#vehicle_history"
        get "reports/fuel", to: "/reports/fuel#index"
        get "reports/incidents", to: "/reports/incidents#index"
        get "reports/compliance", to: "/reports/compliance#index"

        get "audit/logs", to: "/audit/logs#index"
        get "audit/logs/user/:user_id", to: "/audit/logs#by_user"
        get "audit/logs/:resource_type/:resource_id", to: "/audit/logs#resource"
        get "audit/summary", to: "/audit/logs#summary"
        get "audit/export", to: "/audit/logs#export"
        # Backward-compatible aliases used by older admin/web clients
        get "admin/audit_logs", to: "/audit/logs#index"
        get "admin/audit_trail", to: "/audit/logs#index"
        get "action_history", to: "/audit/logs#index"

        resources :incidents, only: [:index, :show, :create, :update], controller: "/incidents" do
          member do
            patch :status, to: "/incidents#update_status"
          end
          collection do
            get :dashboard, to: "/incidents#dashboard"
          end
        end
        post "incidents/:incident_id/witnesses", to: "/incidents/witnesses#create"
        patch "incidents/:incident_id/witnesses/:witness_id", to: "/incidents/witnesses#update"
        post "incidents/:incident_id/evidence", to: "/incidents/evidence#create"
        get "incidents/:incident_id/evidence", to: "/incidents/evidence#index"
        get "incidents/:incident_id/comments", to: "/incidents/comments#index"
        post "incidents/:incident_id/comments", to: "/incidents/comments#create"
        post "incidents/:incident_id/insurance_claims", to: "/incidents/insurance_claims#create"
        patch "incidents/:incident_id/insurance_claims/:claim_id", to: "/incidents/insurance_claims#update"

        get "compliance/requirements", to: "/compliance/requirements#index"
        post "compliance/requirements", to: "/compliance/requirements#create"
        patch "compliance/requirements/:id", to: "/compliance/requirements#update"
        get "compliance/checks", to: "/compliance/checks#index"
        post "trips/:trip_id/compliance/verify", to: "/compliance/verifications#create"
        get "compliance/violations", to: "/compliance/violations#index"
        get "compliance/violations/:id", to: "/compliance/violations#show"
        patch "compliance/violations/:id", to: "/compliance/violations#update"
        post "compliance/violations/:id/waiver", to: "/compliance/violations#waiver"
        get "compliance/dashboard", to: "/compliance/dashboard#show"

        get "compliance/vehicle/:vehicle_id", to: "/compliance/checks#vehicle"
        get "compliance/driver/:driver_id", to: "/compliance/checks#driver"

        get "me/incidents", to: "/me/incidents#index"
        post "me/incidents", to: "/me/incidents#create"
        post "me/incidents/:id/evidence", to: "/me/incidents#create_evidence"

        namespace :admin, module: "admin" do
          resources :escalation_rules, only: [:index, :create, :update]
          get "escalations/active", to: "escalations#active"
        end
        resources :clients, controller: "/api/v1/clients", only: [:index, :create, :show, :update] do
          member do
            get :shipments, to: "/api/v1/clients#shipments"
            get :users, to: "/api/v1/clients#users"
            post "users", to: "/api/v1/clients#create_user"
            patch "users/:user_id", to: "/api/v1/clients#update_user"
            post "invoices", to: "/api/v1/clients#create_invoice"
          end
        end
        post "invoices/:id/send", to: "/api/v1/clients#send_invoice"
        post "invoices/:id/payment", to: "/api/v1/clients#record_payment"
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

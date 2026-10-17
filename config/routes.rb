# frozen_string_literal: true

Rails.application.routes.draw do
  mount MissionControl::Jobs::Engine, at: "/jobs"

  get  "sign_in", to: "sessions#new", as: :sign_in
  post "sign_in", to: "sessions#create"

  get  "provider", to: "provider_sessions#new", as: :provider_sign_in
  post "provider", to: "provider_sessions#create"
  resource :provider_invitation, path: "provider/invitation", only: [ :show, :update ]
  resource :provider_password_reset, path: "provider/password", only: [ :create, :edit, :update ], path_names: { edit: "new" }
  resource :provider_password_reset_code, path: "provider/password/code", only: [ :show, :create ]

  namespace :internal do
    resources :provider_invitations, only: [ :create ]
  end

  resources :sessions, only: [ :destroy, :edit, :update ]
  resource :users, only: [ :destroy ]
  resources :notifications, only: [] do
    patch :close, on: :member
  end

  # The GET to /auth/google_oauth2 (start of the flow) is intercepted by the
  # OmniAuth middleware before it reaches the router — only the callback and
  # failure paths need a route.
  get "auth/google_oauth2/callback", to: "omniauth_callbacks#google_oauth2"
  get "auth/failure", to: "omniauth_callbacks#failure"

  namespace :identity do
    resource :email_verification, only: [ :show, :create ]
  end

  namespace :settings do
    resource :profile, only: [ :show, :update ]
    resource :password, only: [ :show, :update ]
    resource :email, only: [ :show, :update ]
    resources :sessions, only: [ :index ]
    resources :notifications, only: [ :index, :update ]
    inertia :appearance
  end

  namespace :provider do
    resource :onboarding, only: [ :show, :update ], controller: "onboarding"
    get "account", to: "accounts#show", as: :account
    get "operational_settings", to: "operational_settings#show", as: :operational_settings
    resource :payment_details, only: [ :show, :update ]
    resource :deliveries, only: [ :show, :update ]
    resources :menus, except: [ :index, :show ] do
      post :publish, on: :collection
    end
    resources :orders, only: [ :index, :show ] do
      member do
        patch :confirm
        patch :reject
      end
    end
    resources :collections, only: [ :index, :show ] do
      resources :debt_reminders, only: [ :create ]
    end
    resources :invoices, only: [ :create, :destroy ] do
      get :file, on: :member
    end
    resource :order_deadline, only: [ :update ]
    resources :closures, only: [ :create, :update, :destroy ]
    get "dashboard", to: "dashboard#index", as: :dashboard
    resources :payments, only: [ :update ] do
      get :receipt, on: :member
    end
  end

  resources :schedules, only: [ :index, :create, :destroy ] do
    patch :availability, on: :member
  end

  scope module: :consumer do
    get "dashboard", to: "dashboard#index", as: :dashboard
    resource :profile, only: [ :show ]
    get "dashboard/confirmation", to: "dashboard#confirmation", as: :dashboard_confirmation

    resources :menus, only: [ :index ]
    resources :delivery_addresses, only: [ :create ]

    resources :orders, only: [ :index, :show, :create, :update ] do
      patch :cancel, on: :member, as: :cancel_consumer
    end

    resources :payments, only: [ :create, :update, :destroy ] do
      get :receipt, on: :member
    end

    resources :accounts, only: [ :index, :show ]
  end

  namespace :admin do
    get "dashboard", to: "dashboard#index", as: :dashboard
    get "account", to: "accounts#show", as: :account
    get "preferences", to: "preferences#show", as: :preferences
    resources :benefit_configurations, only: [ :index, :create ]
    resources :special_subsidies, only: [ :create, :update, :destroy ]

    resource :debt_alert, only: [ :update ]
    resources :consumers, only: [ :index, :show ] do
      resources :debt_reminders, only: [ :create ]
    end

    resources :invoices, only: [ :index ] do
      get :file, on: :member
    end
    resources :payments, only: [ :index, :show, :create, :destroy ] do
      get :receipt, on: :member
    end
  end

  root "home#index"
  get "proveedor", to: redirect("/provider"), as: :provider_welcome
  get "rrhh", to: "home#admin", as: :admin_welcome

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  match "500", to: "errors#internal_server_error", via: :all, format: false
  get "*unmatched_path", to: "errors#not_found", format: false,
      constraints: ->(request) { !request.path.start_with?("/rails/active_storage") }
end

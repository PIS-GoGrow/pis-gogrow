# frozen_string_literal: true

Rails.application.routes.draw do
  mount MissionControl::Jobs::Engine, at: "/jobs"

  get  "sign_in", to: "sessions#new", as: :sign_in
  post "sign_in", to: "sessions#create"
  get  "sign_up", to: "users#new", as: :sign_up
  post "sign_up", to: "users#create"

  resources :sessions, only: [ :destroy ]
  resource :users, only: [ :destroy ]

  # The GET to /auth/google_oauth2 (start of the flow) is intercepted by the
  # OmniAuth middleware before it reaches the router — only the callback and
  # failure paths need a route.
  get "auth/google_oauth2/callback", to: "omniauth_callbacks#google_oauth2"
  get "auth/failure", to: "omniauth_callbacks#failure"

  namespace :identity do
    resource :email_verification, only: [ :show, :create ]
    resource :password_reset,     only: [ :new, :edit, :create, :update ]
  end

  get "dashboard(/:role)", to: "dashboard#index", as: :dashboard, constraints: { role: /provider/ }

  namespace :settings do
    resource :profile, only: [ :show, :update ]
    resource :password, only: [ :show, :update ]
    resource :email, only: [ :show, :update ]
    resources :sessions, only: [ :index ]
    inertia :appearance
  end

  resources :menus

  root "home#index"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check
end

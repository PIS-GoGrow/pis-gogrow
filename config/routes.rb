# frozen_string_literal: true

# Los paths están en español y llevan el nombre de la pantalla que abren; los
# nombres de las rutas (helpers) siguen en inglés para no tocar el código. Los
# prefijos /proveedor y /rrhh están traducidos para unificar toda la app.
Rails.application.routes.draw do
  mount MissionControl::Jobs::Engine, at: "/jobs"

  get  "iniciar-sesion", to: "sessions#new", as: :sign_in
  post "iniciar-sesion", to: "sessions#create", as: nil

  get  "proveedor", to: "provider_sessions#new", as: :provider_sign_in
  post "proveedor", to: "provider_sessions#create"
  resource :provider_invitation, path: "proveedor/invitacion", only: [ :show, :update ]
  resource :provider_password_reset, path: "proveedor/contrasena", only: [ :create, :edit, :update ], path_names: { edit: "nueva" }
  resource :provider_password_reset_code, path: "proveedor/contrasena/codigo", only: [ :show, :create ]

  get "provider", to: redirect("/proveedor"), as: :provider_welcome
  get "provider/*path", to: redirect("/proveedor/%{path}")
  get "admin", to: redirect("/rrhh")
  get "admin/*path", to: redirect("/rrhh/%{path}")

  namespace :internal do
    resources :provider_invitations, only: [ :create ]
  end

  resources :sessions, path: "sesiones", only: [ :destroy, :edit, :update ], path_names: { edit: "editar" }
  resource :users, path: "usuario", only: [ :destroy ]
  resources :notifications, path: "notificaciones", only: [] do
    patch :close, on: :member, path: "cerrar"
  end

  # The GET to /auth/google_oauth2 (start of the flow) is intercepted by the
  # OmniAuth middleware before it reaches the router — only the callback and
  # failure paths need a route.
  get "auth/google_oauth2/callback", to: "omniauth_callbacks#google_oauth2"
  get "auth/failure", to: "omniauth_callbacks#failure"

  namespace :identity, path: "identidad" do
    resource :email_verification, path: "verificacion-de-correo", only: [ :show, :create ]
  end

  namespace :settings, path: "configuracion" do
    resource :profile, path: "perfil", only: [ :show, :update ]
    resource :password, path: "contrasena", only: [ :show, :update ]
    resource :email, path: "correo-electronico", only: [ :show, :update ]
    resources :sessions, path: "sesiones", only: [ :index ]
    resources :notifications, path: "notificaciones", only: [ :index, :update ]
  end
  # Fuera del namespace para que el path y el componente queden explícitos.
  scope "configuracion" do
    inertia "apariencia" => "settings/appearance", as: :settings_appearance
  end

  namespace :provider, path: "proveedor" do
    resource :onboarding, path: "primeros-pasos", only: [ :show, :update ], controller: "onboarding"
    get "cuenta", to: "accounts#show", as: :account
    get "configuracion-operativa", to: "operational_settings#show", as: :operational_settings
    resource :payment_details, path: "datos-de-cobro", only: [ :show, :update ]
    resource :deliveries, path: "entregas", only: [ :show, :update ]
    resources :menus, path: "platos", except: [ :index, :show ], path_names: { new: "nuevo", edit: "editar" } do
      post :publish, on: :collection, path: "publicar"
    end
    # Importar un menú desde una planilla: la vista previa y la confirmación.
    get  "importar-platos", to: "menu_imports#new", as: :menu_import
    post "importar-platos", to: "menu_imports#create", as: :menu_import_preview
    post "importar-platos/confirmar", to: "menu_imports#confirm", as: :confirm_menu_import
    resources :orders, path: "pedidos", only: [ :index, :show ] do
      member do
        patch :confirm, path: "confirmar"
        patch :reject, path: "rechazar"
      end
    end
    resources :collections, path: "cobros", only: [ :index, :show ] do
      resources :debt_reminders, path: "recordatorios-de-deuda", only: [ :create ]
    end
    resources :invoices, path: "facturas", only: [ :create, :destroy ] do
      get :file, on: :member, path: "archivo"
    end
    resource :order_deadline, path: "limite-de-pedidos", only: [ :update ]
    resources :closures, path: "cierres", only: [ :create, :update, :destroy ]
    get "inicio", to: "dashboard#index", as: :dashboard
    get "inicio/hallazgos", to: "insights#index", as: :insights
    resources :payments, path: "comprobantes", only: [ :update ] do
      get :receipt, on: :member, path: "archivo"
    end
  end

  resources :schedules, path: "publicar-menu", only: [ :index, :create, :destroy ] do
    patch :availability, on: :member, path: "disponibilidad"
  end

  scope module: :consumer do
    get "menu-semanal", to: "dashboard#index", as: :dashboard
    resource :profile, path: "cuenta", only: [ :show ]
    get "menu-semanal/confirmacion", to: "dashboard#confirmation", as: :dashboard_confirmation
    get "menu-semanal/carrito", to: "dashboard#cart", as: :dashboard_cart
    get "menu-semanal/error", to: "dashboard#error", as: :dashboard_error

    resources :menus, path: "menu-del-dia", only: [ :index ]
    resources :delivery_addresses,
              path: "direcciones-de-entrega",
              only: %i[index create update destroy]

    resources :orders, path: "pedidos", path_names: { edit: "editar" }, only: [ :index, :show, :edit, :create, :update ] do
      patch :cancel, on: :member, as: :cancel_consumer, path: "cancelar"
      resource :review, only: [ :new, :create ], path: "calificacion", path_names: { new: "nueva" }
      post :pricing, on: :collection, as: :pricing
    end

    # Las pantallas de resultado no necesitan el pedido: solo informan el envío.
    get "calificacion/gracias", to: "reviews#thanks", as: :review_thanks
    get "calificacion/error", to: "reviews#error", as: :review_error

    resources :payments, path: "comprobantes", only: [ :create, :update, :destroy ] do
      get :receipt, on: :member, path: "archivo"
    end

    get "payments", to: "accounts#index", as: :accounts
    resources :accounts, only: [ :show ]
  end

  namespace :admin, path: "rrhh" do
    get "inicio", to: "dashboard#index", as: :dashboard
    get "cuenta", to: "accounts#show", as: :account
    get "preferencias", to: "preferences#show", as: :preferences
    resources :benefit_configurations, path: "subsidios", only: [ :index, :create ]
    resources :special_subsidies, path: "subsidios-especiales", only: [ :create, :update, :destroy ]

    resource :debt_alert, path: "alerta-de-deuda", only: [ :update ]
    resources :consumers, path: "empleados", only: [ :index, :show ] do
      resources :debt_reminders, path: "recordatorios-de-deuda", only: [ :create ]
    end

    resources :invoices, path: "facturas", only: [ :index ] do
      get :file, on: :member, path: "archivo"
    end
    resources :order_events, path: "auditoria", only: [ :index ]
    resources :payments, path: "pagos", only: [ :index, :show, :create, :destroy ] do
      get :receipt, on: :member, path: "archivo"
    end
  end

  root "home#index"
  get "rrhh", to: "home#admin", as: :admin_welcome

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  match "500", to: "errors#internal_server_error", via: :all, format: false
  get "*unmatched_path", to: "errors#not_found", format: false,
      constraints: ->(request) { !request.path.start_with?("/rails/active_storage") }
end

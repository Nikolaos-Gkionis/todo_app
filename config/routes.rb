Rails.application.routes.draw do
  # Authentication routes
  get    "/login",  to: "sessions#new"
  post   "/login",  to: "sessions#create"
  delete "/logout", to: "sessions#destroy"

  get  "/signup", to: "registrations#new"
  post "/signup", to: "registrations#create"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, or 500 otherwise.
  get "up" => "rails/health#show", as: :rails_health_check

  # Polar webhooks (public, no auth - verification via signature)
  post "/webhooks/polar", to: "webhooks/polar#create"

  # Desktop helper API (Omarchy / peponi CLI) — paid license + optional snapshot
  namespace :api do
    namespace :v1 do
      post   "auth/login",  to: "auth#login"
      delete "auth/logout", to: "auth#logout"
      get    "auth/status", to: "auth#status"
      get    "export",            to: "exports#show"
      get    "days/:date",        to: "days#show",        constraints: { date: /\d{4}-\d{2}-\d{2}/ }
      post   "days/:date/tasks",  to: "days#create_task", constraints: { date: /\d{4}-\d{2}-\d{2}/ }
      delete "todos/:id",         to: "todos#destroy"
      get    "not_yet",           to: "not_yet#show"
      post   "not_yet/tasks",     to: "not_yet#create_task"
    end
  end

  # PWA routes (must be before other routes to avoid conflicts)
  get "/manifest.json", to: "pwa#manifest", as: "pwa_manifest"
  get "/service-worker.js", to: "pwa#service_worker", as: "pwa_service_worker", defaults: { format: :js }

  # Marketing pages (public)
  root "marketing#landing"
  get "/pricing", to: "marketing#pricing"
  get "/how-to", to: "marketing#how_to"
  get "/why", to: "marketing#why"

  # Contact form (public)
  get "/contact", to: "contact#new", as: "contact"
  post "/contact", to: "contact#create"

  # Legal pages (public)
  get "/privacy", to: "marketing#privacy", as: "privacy_policy"
  get "/terms", to: "marketing#terms", as: "terms_of_service"

  # App routes (authenticated)
  get "/app", to: "dashboard#index", as: "app_root"
  get "/offline", to: "pages#offline"

  scope "/app" do
    resources :pages do
      collection do
        patch :reorder
      end
    end

    resources :todos, only: [ :create, :edit, :update, :destroy ] do
      collection do
        patch :reorder
      end
    end

    # Settings
    get "/settings", to: "settings#index", as: "settings"
    patch "/settings", to: "settings#update"
    get "/settings/delete", to: "settings#delete", as: "delete_account"
    delete "/settings", to: "settings#destroy"
    post "/settings/theme", to: "settings#update_theme"

    # Trial Management
    get "/trial/status", to: "trial#status", as: "trial_status"
    post "/trial/start", to: "trial#start", as: "start_trial"
    post "/trial/extend", to: "trial#extend_trial", as: "extend_trial"
    get "/trial/export", to: "trial#export_data", as: "export_trial_data"
    get "/trial/download", to: "trial#download", as: "trial_download"

    # PWA Install Guide (post-payment only, no marketing mix)
    get "/install", to: "install#show", as: "install_pwa"

    # App Downloads
    get "/download", to: "downloads#show", as: "download"
    get "/download/app", to: "downloads#download", as: "download_app"
    post "/download/token", to: "downloads#generate_token", as: "generate_download_token"
    post "/download/mark", to: "downloads#mark_downloaded", as: "mark_downloaded"

    # Purchase flow (post-checkout)
    get "/purchase/complete", to: "purchase#complete", as: "purchase_complete"
    get "/purchase/status", to: "purchase#status", as: "purchase_status"

    # Polar Integration (Merchant of Record)
    post "/polar/create-checkout", to: "polar#create_checkout", as: "create_checkout_session"
    get "/polar/success", to: "polar#success", as: "success_polar"
    get "/polar/cancel", to: "polar#cancel", as: "cancel_polar"

    # Polar Webhooks (no /app prefix - must be publicly accessible)
    # Legacy Stripe (kept for historical data)
    post "/stripe/create-checkout-session", to: "legacy/stripe#create_checkout_session", as: "legacy_create_checkout_session"
    get "/stripe/success", to: "legacy/stripe#success", as: "success_stripe"
    get "/stripe/cancel", to: "legacy/stripe#cancel", as: "cancel_stripe"
    get "/stripe/customer-portal", to: "legacy/stripe#customer_portal", as: "customer_portal"
    post "/stripe/webhook", to: "legacy/stripe#webhook"
  end
end

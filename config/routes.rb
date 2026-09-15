Rails.application.routes.draw do
  # Authentication routes
  get    "/login",  to: "sessions#new"
  post   "/login",  to: "sessions#create"
  delete "/logout", to: "sessions#destroy"

  get  "/signup", to: "registrations#new"
  post "/signup", to: "registrations#create"

  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post   "auth/login",  to: "auth#login"
      delete "auth/logout", to: "auth#logout"
      get    "auth/status", to: "auth#status"
      get    "export",            to: "exports#show"
      get    "days/:date",        to: "days#show",        constraints: { date: /\d{4}-\d{2}-\d{2}/ }
      post   "days/:date/tasks",  to: "days#create_task", constraints: { date: /\d{4}-\d{2}-\d{2}/ }
      patch  "days/:date/reorder", to: "days#reorder", constraints: { date: /\d{4}-\d{2}-\d{2}/ }
      delete "todos/:id",         to: "todos#destroy"
      patch  "todos/:id",         to: "todos#update"
      get    "not_yet",           to: "not_yet#show"
      post   "not_yet/tasks",     to: "not_yet#create_task"
    end
  end

  get "/manifest.json", to: "pwa#manifest", as: "pwa_manifest"
  get "/service-worker.js", to: "pwa#service_worker", as: "pwa_service_worker", defaults: { format: :js }

  root "marketing#landing"
  get "/pricing", to: redirect("/")
  get "/how-to", to: "marketing#how_to"
  get "/why", to: "marketing#why"

  get "/contact", to: "contact#new", as: "contact"
  post "/contact", to: "contact#create"

  get "/privacy", to: "marketing#privacy", as: "privacy_policy"
  get "/terms", to: "marketing#terms", as: "terms_of_service"

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

    get "/settings", to: "settings#index", as: "settings"
    patch "/settings", to: "settings#update"
    get "/settings/delete", to: "settings#delete", as: "delete_account"
    delete "/settings", to: "settings#destroy"
    post "/settings/theme", to: "settings#update_theme"

    get "/trial/status", to: "trial#status", as: "trial_status"
    get "/trial/export", to: "trial#export_data", as: "export_trial_data"

    get "/install", to: "install#show", as: "install_pwa"

    get "/download", to: "downloads#show", as: "download"
    get "/download/app", to: "downloads#download", as: "download_app"
    post "/download/token", to: "downloads#generate_token", as: "generate_download_token"
    post "/download/mark", to: "downloads#mark_downloaded", as: "mark_downloaded"
  end
end

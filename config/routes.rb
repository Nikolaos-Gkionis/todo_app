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

  # Marketing pages (public)
  root "marketing#landing"
  get "/pricing", to: "marketing#pricing"
  get "/how-to", to: "marketing#how_to"
  get "/why", to: "marketing#why"

  # App routes (authenticated)
  get "/app", to: "pages#index", as: "app_root"
  get "/offline", to: "pages#offline"
  scope "/app" do
    resources :pages do
      resources :todos, except: [ :show ] do
        collection do
          patch :reorder
        end
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
    post "/trial/extend", to: "trial#extend", as: "extend_trial"
    get "/trial/export", to: "trial#export_data", as: "export_trial_data"
    get "/trial/download", to: "trial#download", as: "trial_download"

    # App Downloads
    get "/download", to: "downloads#show", as: "download"
    get "/download/app", to: "downloads#download", as: "download_app"
    post "/download/token", to: "downloads#generate_token", as: "generate_download_token"
    post "/download/mark", to: "downloads#mark_downloaded", as: "mark_downloaded"

    # Stripe Integration
    post "/stripe/create-checkout-session", to: "stripe#create_checkout_session", as: "create_checkout_session"
    get "/stripe/success", to: "stripe#success", as: "success_stripe"
    get "/stripe/cancel", to: "stripe#cancel", as: "cancel_stripe"
    get "/stripe/customer-portal", to: "stripe#customer_portal", as: "customer_portal"
    post "/stripe/webhook", to: "stripe#webhook"
  end
end

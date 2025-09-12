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

  # App routes (authenticated)
  get "/app", to: "pages#index", as: "app_root"
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

    # Stripe Integration
    post "/stripe/create-checkout-session", to: "stripe#create_checkout_session", as: "create_checkout_session"
    get "/stripe/success", to: "stripe#success", as: "success_stripe"
    get "/stripe/cancel", to: "stripe#cancel", as: "cancel_stripe"
    get "/stripe/customer-portal", to: "stripe#customer_portal", as: "customer_portal"
  end
end

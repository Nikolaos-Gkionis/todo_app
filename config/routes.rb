Rails.application.routes.draw do
  # Authentication routes
  get    '/login',  to: 'sessions#new'
  post   '/login',  to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'
  
  get  '/signup', to: 'registrations#new'
  post '/signup', to: 'registrations#create'
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, or 500 otherwise.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root 'projects#index'
  
  resources :projects do
    resources :todos, except: [:show] do
      collection do
        patch :reorder
      end
    end
  end
end
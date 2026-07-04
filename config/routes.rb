Rails.application.routes.draw do
  root "dashboard#index"

  resources :clients
  resources :invoices do
    member do
      get :print
      patch :update_status
    end
  end
  resource :company_setting, only: %i[edit update]

  get "up" => "rails/health#show", as: :rails_health_check
end

Rails.application.routes.draw do
  devise_for :users

  # 認証後のルーティング
  authenticate :user do
    resources :facilities
    resources :patients do
      resource :questionnaire, only: [:new, :create, :edit, :update, :destroy]
    end
    resources :cost_sheets
    resources :medical_records
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "facilities#index"
end

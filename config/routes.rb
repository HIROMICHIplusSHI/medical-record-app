Rails.application.routes.draw do
  devise_for :users

  # 認証後のルーティング
  authenticate :user do
    # ダッシュボード
    get 'dashboard', to: 'dashboards#index'
    get 'dashboard/export', to: 'dashboards#export', as: :export_dashboard

    resources :facilities
    resources :patients do
      resource :questionnaire, only: [:new, :create, :show, :edit, :update, :destroy]
    end
    resources :cost_sheets
    resources :tags
    resources :medical_records do
      member do
        delete :remove_photo
      end
    end

    resources :invoices do
      member do
        post :generate_pdf
        get :download_pdf
        post :refresh_items
      end
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "facilities#index"
end

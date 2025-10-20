Rails.application.routes.draw do
  devise_for :users

  # 管理者専用ルート（管理者のみアクセス可能）
  namespace :admin do
    root to: 'dashboard#index'

    resources :announcements do
      member do
        patch :publish
        patch :archive
      end
    end

    resources :users, only: [:index, :show] do
      member do
        patch :toggle_role
      end
    end
  end

  # ユーザー（施術者）専用ルート（一般ユーザーのみアクセス可能）
  authenticated :user, ->(user) { user.user? } do
    # ホームページ（ユーザー専用）
    root to: 'home#index', as: :user_root

    get 'home', to: 'home#index', as: :home
    post 'home/dismiss_announcement', to: 'home#dismiss_announcement'

    # ダッシュボード
    get 'dashboard', to: 'dashboards#index'
    get 'dashboard/export', to: 'dashboards#export', as: :export_dashboard

    # マイページ
    get 'mypage', to: 'mypage#edit'
    patch 'mypage', to: 'mypage#update'

    resources :facilities
    resources :consent_form_templates do
      member do
        patch :sort_items
      end
    end
    resources :patients do
      resource :questionnaire, only: [:new, :create, :show, :edit, :update, :destroy]
    end
    resources :cost_sheets
    resources :tags
    resources :medical_records do
      member do
        delete :remove_photo
      end
      resources :patient_consents, only: [:new, :create, :index, :show, :destroy] do
        member do
          post :generate_pdf
          get :download_pdf
          get :preview_pdf
        end
      end
    end

    resources :invoices do
      member do
        post :generate_pdf
        get :download_pdf
        get :preview_pdf
        post :refresh_items
      end
    end
  end

  # 未認証ユーザー用のroot（ログインページにリダイレクト）
  unauthenticated do
    root to: redirect('/users/sign_in'), as: :unauthenticated_root
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end

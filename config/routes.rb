Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    passwords: 'users/passwords'
  }

  # 管理者専用ルート（管理者のみアクセス可能）
  namespace :admin do
    root to: 'dashboard#index'

    resources :announcements do
      member do
        patch :publish
        patch :archive
      end
    end

    resources :invitation_codes do
      collection do
        get :export
      end
      member do
        patch :suspend
        patch :activate
      end
    end

    resources :users, only: [:index, :show] do
      member do
        patch :toggle_role
      end
    end

    resources :inquiries, only: [:index, :show, :update] do
      resources :inquiry_messages, only: [:create]
    end
  end

  # パブリックroot（ログイン前のウェルカムページ）
  root 'welcome#index'

  # デモアカウントへのワンクリックログイン（DEMO_LOGIN_ENABLED=true の環境のみ機能する）
  post 'demo_login', to: 'demo_sessions#create'

  # 利用規約・プライバシーポリシー（未認証でもアクセス可能）
  get 'terms', to: 'pages#terms'
  get 'privacy', to: 'pages#privacy'

  # 既存ユーザー向け規約同意確認ページ（認証必須）
  get 'accept_terms', to: 'pages#accept_terms'
  patch 'accept_terms', to: 'pages#update_terms_acceptance'

  # ユーザー（施術者）専用ルート
  # 認証はApplicationControllerのbefore_action :authenticate_user!で保護

  # ユーザーダッシュボード（ログイン後のホーム画面）
  get 'dashboard', to: 'user_dashboard#index', as: :user_dashboard

  # 売上ダッシュボード
  get 'dashboard/revenue', to: 'dashboards#index', as: :revenue_dashboard
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
    # 患者起点の施術履歴（一覧・患者を指定した新規作成）
    resources :medical_records, only: [:index, :new]
  end
  resources :cost_sheets
  resources :tags, except: :show
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

  # お問い合わせ
  resources :inquiries, only: [:index, :show, :new, :create] do
    resources :inquiry_messages, only: [:create]
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end

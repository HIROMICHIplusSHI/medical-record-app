# Phase 6-A-2: 管理者ダッシュボード・ユーザー管理機能 - 実装計画

**計画作成日**: 2025-10-20
**実装予定期間**: 2-3日
**前提条件**: Phase 6-A-1完了（RBAC基盤・ホームページ・お知らせ機能）

---

## 📋 Phase 6-A-2の目的

Phase 6-A-1で構築したRBAC基盤の上に、管理者専用機能を実装します。管理者が施術者アカウント管理・お知らせ管理を行える管理画面を構築し、**管理者は施術者にならず、アプリ管理に特化**する設計とします。

---

## 🎯 実装目標

### Step 4: 管理者ダッシュボード実装
- 管理者専用ダッシュボード（システム統計表示）
- お知らせ管理機能（CRUD）
- Admin::AnnouncementsController実装
- AnnouncementPolicy実装（Phase 6-A-1で未実装）
- 管理者専用レイアウト作成

### Step 5: ユーザー管理機能実装
- ユーザー一覧・詳細表示
- 権限変更機能（一般ユーザー ↔ 管理者）
- Admin::UsersController実装
- UserPolicy実装
- 管理者作成機能（rake task）

### ルート分離・リダイレクト実装
- 管理者ルート: `namespace :admin` に集約
- ユーザールート: 施術者向けルート（現行通り）
- `after_sign_in_path_for` によるロール別リダイレクト
- 管理者は施術者機能にアクセス不可

---

## 🏗️ 実装内容詳細

### Step 4-1: 管理者ダッシュボード

#### 4-1-1. ルーティング

```ruby
# config/routes.rb

Rails.application.routes.draw do
  devise_for :users

  # 管理者専用ルート（管理者のみアクセス可能）
  namespace :admin do
    root to: 'dashboard#index'  # /admin → 管理者ダッシュボード

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

  # ユーザー（施術者）専用ルート
  authenticated :user, ->(user) { user.user? } do
    root to: 'home#index', as: :user_root

    # 施術者機能
    resource :home, only: [:index], controller: 'home' do
      post :dismiss_announcement
    end

    resources :medical_records
    resources :patients
    resources :facilities
    # ... その他の施術者機能
  end

  # デフォルトのroot（未認証時）
  root to: 'home#index'
end
```

#### 4-1-2. Admin::BaseController（管理者専用ベースコントローラー）

```ruby
# app/controllers/admin/base_controller.rb

module Admin
  class BaseController < ApplicationController
    before_action :require_admin!

    layout 'admin'  # 管理者専用レイアウト

    private

    def require_admin!
      unless current_user&.admin?
        flash[:alert] = '管理者権限が必要です。'
        redirect_to root_path
      end
    end
  end
end
```

#### 4-1-3. Admin::DashboardController

```ruby
# app/controllers/admin/dashboard_controller.rb

module Admin
  class DashboardController < Admin::BaseController
    def index
      @total_users = User.count
      @total_medical_records = MedicalRecord.count
      @active_announcements = Announcement.active.count

      # 最近登録されたユーザー
      @recent_users = User.order(created_at: :desc).limit(5)

      # 最近公開されたお知らせ
      @recent_announcements = Announcement.published
                                          .order(published_at: :desc)
                                          .limit(5)
    end
  end
end
```

#### 4-1-4. 管理者ダッシュボードビュー

```erb
<!-- app/views/admin/dashboard/index.html.erb -->

<div class="container mx-auto px-4 py-8">
  <h1 class="text-3xl font-bold mb-8">管理者ダッシュボード</h1>

  <!-- システム統計 -->
  <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
    <!-- 総ユーザー数 -->
    <div class="card bg-base-100 shadow-xl">
      <div class="card-body">
        <h2 class="card-title text-sm text-gray-600">総ユーザー数</h2>
        <p class="text-4xl font-bold text-primary"><%= @total_users %></p>
        <%= link_to "ユーザー管理へ", admin_users_path, class: "btn btn-outline btn-sm mt-2" %>
      </div>
    </div>

    <!-- 総カルテ数 -->
    <div class="card bg-base-100 shadow-xl">
      <div class="card-body">
        <h2 class="card-title text-sm text-gray-600">総カルテ数</h2>
        <p class="text-4xl font-bold text-secondary"><%= @total_medical_records %></p>
      </div>
    </div>

    <!-- アクティブなお知らせ -->
    <div class="card bg-base-100 shadow-xl">
      <div class="card-body">
        <h2 class="card-title text-sm text-gray-600">公開中のお知らせ</h2>
        <p class="text-4xl font-bold text-accent"><%= @active_announcements %></p>
        <%= link_to "お知らせ管理へ", admin_announcements_path, class: "btn btn-outline btn-sm mt-2" %>
      </div>
    </div>
  </div>

  <!-- クイックリンク -->
  <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
    <!-- 最近登録されたユーザー -->
    <div class="card bg-base-100 shadow-xl">
      <div class="card-body">
        <h2 class="card-title mb-4">最近登録されたユーザー</h2>

        <% if @recent_users.any? %>
          <div class="overflow-x-auto">
            <table class="table table-zebra">
              <tbody>
                <% @recent_users.each do |user| %>
                  <tr>
                    <td>
                      <%= link_to user.email, admin_user_path(user), class: "link link-primary" %>
                    </td>
                    <td>
                      <span class="badge <%= user.admin? ? 'badge-error' : 'badge-info' %>">
                        <%= user.admin? ? '管理者' : 'ユーザー' %>
                      </span>
                    </td>
                    <td class="text-sm text-gray-500">
                      <%= user.created_at.strftime('%Y/%m/%d') %>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        <% else %>
          <p class="text-gray-500">ユーザーがいません</p>
        <% end %>
      </div>
    </div>

    <!-- 最近公開されたお知らせ -->
    <div class="card bg-base-100 shadow-xl">
      <div class="card-body">
        <h2 class="card-title mb-4">最近公開されたお知らせ</h2>

        <% if @recent_announcements.any? %>
          <div class="space-y-2">
            <% @recent_announcements.each do |announcement| %>
              <div class="border-l-4 <%= announcement.severity %>-border pl-3">
                <%= link_to announcement.title, admin_announcement_path(announcement), class: "link link-primary" %>
                <p class="text-xs text-gray-500">
                  <%= announcement.published_at.strftime('%Y/%m/%d %H:%M') %>
                </p>
              </div>
            <% end %>
          </div>
        <% else %>
          <p class="text-gray-500">お知らせがありません</p>
        <% end %>
      </div>
    </div>
  </div>
</div>
```

---

### Step 4-2: お知らせ管理機能（Admin::AnnouncementsController）

#### 4-2-1. Admin::AnnouncementsController

```ruby
# app/controllers/admin/announcements_controller.rb

module Admin
  class AnnouncementsController < Admin::BaseController
    before_action :set_announcement, only: [:show, :edit, :update, :destroy, :publish, :archive]

    def index
      @q = Announcement.ransack(params[:q])
      @announcements = @q.result
                         .includes(:author)
                         .order(created_at: :desc)
                         .page(params[:page])

      authorize Announcement
    end

    def show
      authorize @announcement
    end

    def new
      @announcement = Announcement.new
      authorize @announcement
    end

    def create
      @announcement = Announcement.new(announcement_params)
      @announcement.author = current_user

      authorize @announcement

      if @announcement.save
        redirect_to admin_announcement_path(@announcement), notice: 'お知らせを作成しました。'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @announcement
    end

    def update
      authorize @announcement

      if @announcement.update(announcement_params)
        redirect_to admin_announcement_path(@announcement), notice: 'お知らせを更新しました。'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @announcement

      @announcement.update(status: :archived)
      redirect_to admin_announcements_path, notice: 'お知らせをアーカイブしました。'
    end

    def publish
      authorize @announcement

      @announcement.published_at ||= Time.current
      @announcement.status = :published

      if @announcement.save
        redirect_to admin_announcement_path(@announcement), notice: 'お知らせを公開しました。'
      else
        redirect_to admin_announcement_path(@announcement), alert: 'お知らせの公開に失敗しました。'
      end
    end

    def archive
      authorize @announcement

      @announcement.update(status: :archived)
      redirect_to admin_announcement_path(@announcement), notice: 'お知らせをアーカイブしました。'
    end

    private

    def set_announcement
      @announcement = Announcement.find(params[:id])
    end

    def announcement_params
      params.require(:announcement).permit(
        :title,
        :body,
        :severity,
        :published_at,
        :expires_at,
        :display_order,
        :status
      )
    end
  end
end
```

#### 4-2-2. AnnouncementPolicy（Phase 6-A-1で未実装）

```ruby
# app/policies/announcement_policy.rb

class AnnouncementPolicy < ApplicationPolicy
  def index?
    user.admin?
  end

  def show?
    user.admin?
  end

  def create?
    user.admin?
  end

  def new?
    create?
  end

  def update?
    user.admin?
  end

  def edit?
    update?
  end

  def destroy?
    user.admin?
  end

  def publish?
    user.admin?
  end

  def archive?
    user.admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.active
      end
    end
  end
end
```

---

### Step 5: ユーザー管理機能

#### 5-1. Admin::UsersController

```ruby
# app/controllers/admin/users_controller.rb

module Admin
  class UsersController < Admin::BaseController
    before_action :set_user, only: [:show, :toggle_role]

    def index
      @q = User.ransack(params[:q])
      @users = @q.result
                 .order(created_at: :desc)
                 .page(params[:page])

      authorize User
    end

    def show
      authorize @user

      # ユーザーの統計情報
      @stats = {
        medical_records_count: @user.medical_records.count,
        patients_count: @user.patients.count,
        facilities_count: @user.facilities.count,
      }
    end

    def toggle_role
      authorize @user

      # 自分自身の権限変更を防止
      if @user == current_user
        redirect_to admin_user_path(@user), alert: '自分自身の権限は変更できません。'
        return
      end

      # 最後の管理者を削除させない
      if @user.admin? && User.admin.count == 1
        redirect_to admin_user_path(@user), alert: '最後の管理者の権限は変更できません。'
        return
      end

      new_role = @user.admin? ? :user : :admin
      @user.allow_role_change!

      if @user.update(role: new_role)
        role_name = @user.admin? ? '管理者' : 'ユーザー'
        redirect_to admin_user_path(@user), notice: "ユーザーの権限を#{role_name}に変更しました。"
      else
        redirect_to admin_user_path(@user), alert: '権限の変更に失敗しました。'
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end
  end
end
```

#### 5-2. UserPolicy

```ruby
# app/policies/user_policy.rb

class UserPolicy < ApplicationPolicy
  def index?
    user.admin?
  end

  def show?
    user.admin?
  end

  def toggle_role?
    user.admin? && record != user
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(id: user.id)
      end
    end
  end
end
```

---

### ルート分離・リダイレクト実装

#### ApplicationController拡張

```ruby
# app/controllers/application_controller.rb

class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :authenticate_user!

  # 認可エラー時の処理
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    flash[:alert] = "この操作を実行する権限がありません。"
    redirect_to(request.referrer || root_path)
  end

  # ログイン後のリダイレクト先をロール別に設定
  def after_sign_in_path_for(resource)
    if resource.admin?
      admin_root_path  # /admin
    else
      user_root_path   # /home
    end
  end

  # ログアウト後のリダイレクト先
  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end
end
```

---

## 🎨 管理者専用レイアウト

### app/views/layouts/admin.html.erb

```erb
<!DOCTYPE html>
<html>
  <head>
    <title>電子カルテアプリ - 管理画面</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>

    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>

  <body class="bg-gray-50">
    <!-- 管理者専用ヘッダー -->
    <header class="navbar bg-error text-error-content shadow-lg">
      <div class="navbar-start">
        <%= link_to admin_root_path, class: "btn btn-ghost normal-case text-xl" do %>
          <span>⚙️ 管理画面</span>
        <% end %>
      </div>

      <div class="navbar-center hidden lg:flex">
        <ul class="menu menu-horizontal px-1">
          <li><%= link_to 'ダッシュボード', admin_root_path %></li>
          <li><%= link_to 'ユーザー管理', admin_users_path %></li>
          <li><%= link_to 'お知らせ管理', admin_announcements_path %></li>
        </ul>
      </div>

      <div class="navbar-end">
        <div class="dropdown dropdown-end">
          <label tabindex="0" class="btn btn-ghost btn-circle avatar">
            <div class="w-10 rounded-full bg-white text-error flex items-center justify-center">
              <span class="text-lg font-bold"><%= current_user.email[0].upcase %></span>
            </div>
          </label>
          <ul tabindex="0" class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-base-100 rounded-box w-52">
            <li class="menu-title">
              <span class="text-xs">管理者: <%= current_user.email %></span>
            </li>
            <li><%= button_to 'ログアウト', destroy_user_session_path, method: :delete, class: "btn btn-sm btn-ghost" %></li>
          </ul>
        </div>
      </div>
    </header>

    <!-- フラッシュメッセージ -->
    <% if notice %>
      <div class="alert alert-success mx-4 mt-4">
        <span><%= notice %></span>
      </div>
    <% end %>

    <% if alert %>
      <div class="alert alert-error mx-4 mt-4">
        <span><%= alert %></span>
      </div>
    <% end %>

    <!-- メインコンテンツ -->
    <main>
      <%= yield %>
    </main>

    <!-- フッター -->
    <footer class="footer footer-center p-4 bg-base-300 text-base-content mt-8">
      <div>
        <p>電子カルテアプリ - 管理画面 © 2025</p>
      </div>
    </footer>
  </body>
</html>
```

---

## 🧪 テスト実装計画

### Request Spec

#### Admin::DashboardController

```ruby
# spec/requests/admin/dashboard_spec.rb

require 'rails_helper'

RSpec.describe 'Admin::Dashboard', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:user) { create(:user) }

  describe 'GET /admin' do
    context '管理者の場合' do
      before { sign_in admin }

      it 'ダッシュボードが表示される' do
        get admin_root_path
        expect(response).to have_http_status(:success)
      end

      it '統計情報が表示される' do
        create_list(:user, 3)
        create_list(:medical_record, 5, user: user)
        create_list(:announcement, 2, :published, author: admin)

        get admin_root_path

        expect(response.body).to include('総ユーザー数')
        expect(response.body).to include('4')  # admin + user + 3新規ユーザー
      end
    end

    context '一般ユーザーの場合' do
      before { sign_in user }

      it 'アクセスが拒否される' do
        get admin_root_path
        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include('管理者権限が必要です')
      end
    end

    context '未認証の場合' do
      it 'ログインページにリダイレクトされる' do
        get admin_root_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
```

#### Admin::UsersController

```ruby
# spec/requests/admin/users_spec.rb

require 'rails_helper'

RSpec.describe 'Admin::Users', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:user) { create(:user) }

  describe 'GET /admin/users' do
    before { sign_in admin }

    it 'ユーザー一覧が表示される' do
      create_list(:user, 3)

      get admin_users_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include('ユーザー一覧')
    end
  end

  describe 'PATCH /admin/users/:id/toggle_role' do
    before { sign_in admin }

    it 'ユーザーの権限を変更できる' do
      patch toggle_role_admin_user_path(user)

      expect(user.reload.admin?).to be true
      expect(response).to redirect_to(admin_user_path(user))
      follow_redirect!
      expect(response.body).to include('管理者に変更しました')
    end

    it '自分自身の権限は変更できない' do
      patch toggle_role_admin_user_path(admin)

      expect(admin.reload.admin?).to be true
      expect(response).to redirect_to(admin_user_path(admin))
      follow_redirect!
      expect(response.body).to include('自分自身の権限は変更できません')
    end

    it '最後の管理者の権限は変更できない' do
      # adminのみが管理者の状態
      patch toggle_role_admin_user_path(admin)

      expect(admin.reload.admin?).to be true
      expect(response).to redirect_to(admin_user_path(admin))
      follow_redirect!
      expect(response.body).to include('最後の管理者の権限は変更できません')
    end
  end
end
```

#### Admin::AnnouncementsController

```ruby
# spec/requests/admin/announcements_spec.rb

require 'rails_helper'

RSpec.describe 'Admin::Announcements', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:user) { create(:user) }

  describe 'GET /admin/announcements' do
    context '管理者の場合' do
      before { sign_in admin }

      it 'お知らせ一覧が表示される' do
        create_list(:announcement, 3, author: admin)

        get admin_announcements_path

        expect(response).to have_http_status(:success)
      end
    end

    context '一般ユーザーの場合' do
      before { sign_in user }

      it 'アクセスが拒否される' do
        get admin_announcements_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'POST /admin/announcements' do
    before { sign_in admin }

    it 'お知らせを作成できる' do
      announcement_params = attributes_for(:announcement)

      expect {
        post admin_announcements_path, params: { announcement: announcement_params }
      }.to change(Announcement, :count).by(1)

      expect(response).to redirect_to(admin_announcement_path(Announcement.last))
    end
  end

  describe 'PATCH /admin/announcements/:id/publish' do
    before { sign_in admin }

    let(:announcement) { create(:announcement, author: admin, status: :draft) }

    it 'お知らせを公開できる' do
      patch publish_admin_announcement_path(announcement)

      expect(announcement.reload.published?).to be true
      expect(announcement.published_at).to be_present
      expect(response).to redirect_to(admin_announcement_path(announcement))
    end
  end
end
```

### Policy Spec

```ruby
# spec/policies/announcement_policy_spec.rb

require 'rails_helper'

RSpec.describe AnnouncementPolicy, type: :policy do
  subject { described_class.new(user, announcement) }

  let(:announcement) { create(:announcement, author: admin) }
  let(:admin) { create(:user, :admin) }

  context '管理者の場合' do
    let(:user) { admin }

    it { is_expected.to permit_actions([:index, :show, :create, :update, :destroy, :publish, :archive]) }
  end

  context '一般ユーザーの場合' do
    let(:user) { create(:user) }

    it { is_expected.to forbid_actions([:index, :show, :create, :update, :destroy, :publish, :archive]) }
  end
end
```

---

## 🚀 実装手順（推奨）

### Phase 1: 管理者ダッシュボード基盤（0.5日）

1. **ルーティング設定**
   - `namespace :admin` 追加
   - `root to: 'dashboard#index'` 設定

2. **Admin::BaseController作成**
   - `require_admin!` 実装
   - 管理者専用レイアウト設定

3. **Admin::DashboardController実装**
   - システム統計取得
   - ビュー作成

4. **管理者専用レイアウト作成**
   - `app/views/layouts/admin.html.erb`
   - ヘッダー・ナビゲーション実装

5. **テスト作成**
   - Request Spec（認証・認可・統計表示）

### Phase 2: お知らせ管理機能（0.5-1日）

1. **Admin::AnnouncementsController実装**
   - CRUD操作
   - publish/archiveアクション

2. **AnnouncementPolicy実装**
   - 管理者のみアクセス許可

3. **ビュー作成**
   - 一覧・詳細・作成・編集ページ

4. **テスト作成**
   - Request Spec（CRUD、認可）
   - Policy Spec

### Phase 3: ユーザー管理機能（0.5-1日）

1. **Admin::UsersController実装**
   - 一覧・詳細表示
   - toggle_roleアクション

2. **UserPolicy実装**
   - 管理者のみアクセス許可

3. **ビュー作成**
   - 一覧・詳細ページ

4. **テスト作成**
   - Request Spec（権限変更、バリデーション）
   - Policy Spec

### Phase 4: ルート分離・リダイレクト（0.5日）

1. **ルート整理**
   - 管理者ルート: `namespace :admin`
   - ユーザールート: `authenticated :user, ->(user) { user.user? }`

2. **ApplicationController拡張**
   - `after_sign_in_path_for` 実装
   - ロール別リダイレクト

3. **テスト作成**
   - System Spec（ログイン後のリダイレクト確認）

### Phase 5: 管理者作成機能（0.5日）

1. **rake task作成**
   - `lib/tasks/admin.rake`
   - 管理者作成タスク

2. **ドキュメント作成**
   - 初期管理者作成手順
   - セキュリティ上の注意事項

---

## 🔒 セキュリティチェックリスト

### 実装必須項目

- [ ] Admin::BaseControllerで`require_admin!`実装
- [ ] 全Admin::*Controllerが`Admin::BaseController`を継承
- [ ] AnnouncementPolicyで管理者のみアクセス許可
- [ ] UserPolicyで管理者のみアクセス許可
- [ ] 自分自身の権限変更を防止
- [ ] 最後の管理者削除を防止
- [ ] `after_sign_in_path_for`でロール別リダイレクト
- [ ] Strong Parameters実装

### レビュー項目

- [ ] Brakeman警告なし
- [ ] RuboCop違反なし
- [ ] security-engineerエージェントレビュー（80点以上）
- [ ] quality-engineerエージェントレビュー（90点以上）

---

## 📊 成功基準

### 機能面
- [ ] 管理者ダッシュボードが正常に表示される
- [ ] お知らせ管理機能（CRUD）が動作する
- [ ] ユーザー管理機能（一覧・権限変更）が動作する
- [ ] ロール別リダイレクトが正常に動作する
- [ ] 管理者は施術者機能にアクセスできない

### 品質面
- [ ] テストカバレッジ 80%以上維持
- [ ] RuboCop違反 0件
- [ ] Brakeman警告 0件
- [ ] RSpec全テストパス（0 failures）

### セキュリティ面
- [ ] 管理者権限の厳格な制御
- [ ] 自分自身の権限変更防止
- [ ] 最後の管理者削除防止
- [ ] AnnouncementPolicy/UserPolicy実装

---

## 🤔 検討事項

### 1. 初期管理者作成方法

**案A: Railsコンソール**
```ruby
# 手動実行
User.create!(
  email: 'admin@example.com',
  password: 'secure_password',
  password_confirmation: 'secure_password'
).admin!
```

**案B: rake task（推奨）**
```ruby
# lib/tasks/admin.rake
namespace :admin do
  desc '管理者ユーザーを作成'
  task create: :environment do
    email = ENV['ADMIN_EMAIL'] || 'admin@example.com'
    password = ENV['ADMIN_PASSWORD'] || SecureRandom.alphanumeric(16)

    user = User.create!(
      email: email,
      password: password,
      password_confirmation: password
    )
    user.admin!

    puts "管理者を作成しました:"
    puts "  Email: #{email}"
    puts "  Password: #{password}" unless ENV['ADMIN_PASSWORD']
  end
end

# 実行: bundle exec rake admin:create ADMIN_EMAIL=admin@example.com ADMIN_PASSWORD=secure123
```

**案C: 環境変数による自動作成（本番環境向け）**
```ruby
# db/seeds.rb
if Rails.env.production? && ENV['ADMIN_EMAIL'].present?
  User.find_or_create_by!(email: ENV['ADMIN_EMAIL']) do |user|
    user.password = ENV['ADMIN_PASSWORD']
    user.password_confirmation = ENV['ADMIN_PASSWORD']
  end.admin!
end
```

**推奨**: 案B（rake task）+ 案C（本番環境用seeds.rb）の組み合わせ

### 2. 管理者UI設計

**共通ヘッダー/フッター vs 独立レイアウト**

**独立レイアウト（推奨）**:
- メリット: 権限分離が明確、誤操作防止
- デメリット: レイアウト重複

**実装**: `app/views/layouts/admin.html.erb` 作成
- 赤色ヘッダー（⚙️ 管理画面）で視覚的に区別
- 管理者専用ナビゲーション
- 施術者機能へのリンクなし

### 3. 権限変更の安全性

**制約**:
- 自分自身の権限変更を防止
- 最後の管理者の権限変更を防止

**実装**:
```ruby
# Admin::UsersController#toggle_role

# 自分自身の権限変更を防止
if @user == current_user
  redirect_to admin_user_path(@user), alert: '自分自身の権限は変更できません。'
  return
end

# 最後の管理者を削除させない
if @user.admin? && User.admin.count == 1
  redirect_to admin_user_path(@user), alert: '最後の管理者の権限は変更できません。'
  return
end
```

---

## 📝 次のステップ（Phase 6-B以降）

Phase 6-A-2完了後、以下のフェーズに進みます：

### Phase 6-B: 紹介制度実装（3.5-5.5日）
- InvitationCodeモデル実装
- 会員登録フロー変更（紹介コード必須）
- 管理者：紹介コード管理機能

### Phase 6-C: UI/UX改善（1.5-2.5日）
- ログインページUI改善
- Googleログイン削除
- ヘッダーロゴ設置（PNG対応）

### Phase 6-D: 利用規約整備（1.5-3日）
- 利用規約ページ作成
- プライバシーポリシーページ作成
- 会員登録時の同意機能

---

**作成者**: Claude Code
**作成日**: 2025-10-20

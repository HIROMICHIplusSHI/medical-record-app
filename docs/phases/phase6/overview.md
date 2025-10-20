# Phase 6: 権限管理・紹介制度・UI改善

**作成日**: 2025-10-20
**最終更新**: 2025-10-20
**目標**: 管理者機能実装、紹介制による会員登録、UI/UX改善、利用規約整備

---

## 🎯 Phase 6の目的

1. **権限管理（RBAC）**: 管理者とユーザーを分離し、適切なアクセス制御を実装
2. **紹介制度**: 会員登録を紹介制にして、不特定多数の登録を防ぐ
3. **ホームページ作成**: ヘッダーロゴクリック時の遷移先、アナウンス表示
4. **UI/UX改善**: ログインページ改善、Googleログイン削除
5. **利用規約整備**: 法的コンプライアンスとユーザーへの情報提供

---

## 📋 全体スケジュール（2.5-3.5週間）

| フェーズ | 内容 | 期間 | マイルストーン | 状態 |
|---------|------|------|--------------|------|
| **Phase 6-A** | 権限管理 + アナウンス | 4.5-6.5日 | 管理者機能完成 | 未実装 |
| **Phase 6-B** | 紹介制度実装 | 3.5-5.5日 | 紹介コード機能完成 | 未実装 |
| **Phase 6-C** | UI/UX改善 | 1.5-2.5日 | ホームページ完成 | 未実装 |
| **Phase 6-D** | 利用規約整備 | 1.5-3日 | 法的対応完了 | 未実装 |

---

## Phase 6-A: 権限管理 + アナウンス機能（4.5-6.5日）

### 目標
管理者とユーザーを分離し、管理者専用機能を実装する。

---

### 1. ロールベースアクセス制御（RBAC）

#### 1-1. Userモデル拡張

**マイグレーション**:
```ruby
rails g migration AddRoleToUsers role:integer

# db/migrate/YYYYMMDDHHMMSS_add_role_to_users.rb
class AddRoleToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :role, :integer, default: 0, null: false
    add_index :users, :role
  end
end
```

**モデル**:
```ruby
# app/models/user.rb
class User < ApplicationRecord
  # Role定義
  enum :role, {
    user: 0,    # 一般ユーザー（デフォルト）
    admin: 1    # 管理者
  }

  # 管理者判定
  def admin?
    role == 'admin'
  end
end
```

---

#### 1-2. Pundit導入（認可制御）

**Gemfile**:
```ruby
gem 'pundit'
```

**インストール**:
```bash
bundle install
rails g pundit:install
```

**ApplicationController設定**:
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
end
```

**ベースポリシー**:
```ruby
# app/policies/application_policy.rb
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NotImplementedError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope
  end
end
```

---

### 2. ホームページ作成

#### 2-1. 概要

**目的**:
- ヘッダーロゴクリック時の遷移先
- アナウンス表示（管理者が編集可能）
- ダッシュボードとの分離（ダッシュボードは売上管理専用）

**URL**: `/` または `/home`

**表示内容**:
- アナウンス一覧（管理者が作成）
- クイックリンク（カルテ作成、患者登録など）
- 最近の施術件数（簡易統計）

---

#### 2-2. ルーティング

```ruby
# config/routes.rb
Rails.application.routes.draw do
  root 'home#index'

  # ホームページ
  resource :home, only: [:index], controller: 'home'

  # ダッシュボード（売上管理専用）
  resource :dashboard, only: [:index] do
    get :export_csv
  end

  # ... 他のルート
end
```

---

#### 2-3. HomeController

```ruby
# app/controllers/home_controller.rb
class HomeController < ApplicationController
  def index
    # アクティブなアナウンスを取得
    @active_announcements = Announcement.active.limit(5)

    # 簡易統計（今月の施術件数）
    @this_month_records_count = current_user.medical_records
                                             .where(treatment_date: Date.current.beginning_of_month..Date.current.end_of_month)
                                             .count
  end
end
```

---

#### 2-4. ホームページビュー

```erb
<!-- app/views/home/index.html.erb -->
<div class="container mx-auto px-4 py-8">
  <h1 class="text-3xl font-bold mb-6">ホーム</h1>

  <!-- アナウンスエリア -->
  <% if @active_announcements.any? %>
    <div class="announcements-container mb-8">
      <h2 class="text-xl font-semibold mb-4">お知らせ</h2>

      <% @active_announcements.each do |announcement| %>
        <div class="alert alert-<%= announcement.severity %> mb-3"
             data-controller="dismissible"
             data-announcement-id="<%= announcement.id %>">

          <div class="flex gap-2">
            <!-- アイコン（重要度に応じて） -->
            <% if announcement.critical? %>
              <svg class="w-6 h-6 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/>
              </svg>
            <% elsif announcement.warning? %>
              <svg class="w-6 h-6 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/>
              </svg>
            <% else %>
              <svg class="w-6 h-6 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd"/>
              </svg>
            <% end %>

            <!-- タイトル・本文 -->
            <div class="flex-1">
              <h3 class="font-bold text-base mb-1"><%= announcement.title %></h3>
              <div class="text-sm whitespace-pre-wrap"><%= simple_format(announcement.body) %></div>
              <p class="text-xs opacity-70 mt-2">
                <%= announcement.published_at.strftime('%Y/%m/%d %H:%M') %>
              </p>
            </div>

            <!-- 閉じるボタン -->
            <button type="button"
                    class="btn btn-ghost btn-sm btn-circle flex-shrink-0"
                    data-action="click->dismissible#dismiss"
                    aria-label="閉じる">
              ×
            </button>
          </div>
        </div>
      <% end %>
    </div>
  <% end %>

  <!-- クイックアクション -->
  <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
    <div class="card bg-base-100 shadow">
      <div class="card-body">
        <h2 class="card-title text-sm">今月の施術件数</h2>
        <p class="text-3xl font-bold"><%= @this_month_records_count %></p>
      </div>
    </div>

    <div class="card bg-base-100 shadow hover:shadow-lg transition-shadow">
      <div class="card-body">
        <h2 class="card-title text-sm">カルテ作成</h2>
        <%= link_to "新規作成", new_medical_record_path, class: "btn btn-primary btn-sm" %>
      </div>
    </div>

    <div class="card bg-base-100 shadow hover:shadow-lg transition-shadow">
      <div class="card-body">
        <h2 class="card-title text-sm">売上確認</h2>
        <%= link_to "ダッシュボード", dashboard_path, class: "btn btn-outline btn-sm" %>
      </div>
    </div>
  </div>

  <!-- クイックリンク -->
  <div class="card bg-base-100 shadow">
    <div class="card-body">
      <h2 class="card-title mb-4">クイックリンク</h2>
      <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
        <%= link_to "カルテ一覧", medical_records_path, class: "btn btn-outline" %>
        <%= link_to "患者一覧", patients_path, class: "btn btn-outline" %>
        <%= link_to "施術場所", facilities_path, class: "btn btn-outline" %>
        <%= link_to "請求書", invoices_path, class: "btn btn-outline" %>
      </div>
    </div>
  </div>
</div>
```

---

#### 2-5. Stimulusコントローラー（閉じるボタン）

```javascript
// app/javascript/controllers/dismissible_controller.js
import { Controller } from "@hotwired/stimulus"

// アナウンスの閉じるボタン制御
export default class extends Controller {
  dismiss(event) {
    event.preventDefault()

    // セッションストレージに記録（同一セッション中は非表示）
    const announcementId = this.element.dataset.announcementId
    sessionStorage.setItem(`announcement_dismissed_${announcementId}`, 'true')

    // アニメーション付きで非表示
    this.element.classList.add('opacity-0', 'transition-opacity', 'duration-300')
    setTimeout(() => this.element.remove(), 300)
  }

  connect() {
    // 過去に閉じたアナウンスは表示しない
    const announcementId = this.element.dataset.announcementId
    if (sessionStorage.getItem(`announcement_dismissed_${announcementId}`)) {
      this.element.remove()
    }
  }
}
```

---

### 3. アナウンス管理機能

#### 3-1. Announcementモデル

**マイグレーション**:
```ruby
rails g model Announcement \
  author:references \
  title:string \
  body:text \
  status:integer \
  severity:integer \
  published_at:datetime \
  expires_at:datetime \
  display_order:integer

# db/migrate/YYYYMMDDHHMMSS_create_announcements.rb
class CreateAnnouncements < ActiveRecord::Migration[7.2]
  def change
    create_table :announcements do |t|
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false, limit: 100
      t.text :body, null: false, limit: 1000
      t.integer :status, default: 0, null: false
      t.integer :severity, default: 0, null: false
      t.datetime :published_at
      t.datetime :expires_at
      t.integer :display_order, default: 0, null: false

      t.timestamps
    end

    add_index :announcements, :status
    add_index :announcements, :published_at
    add_index :announcements, :expires_at
    add_index :announcements, :display_order
  end
end
```

**モデル**:
```ruby
# app/models/announcement.rb
class Announcement < ApplicationRecord
  belongs_to :author, class_name: 'User'

  # ステータス管理
  enum :status, {
    draft: 0,      # 下書き
    published: 1,  # 公開中
    archived: 2    # アーカイブ
  }

  # 重要度（表示スタイル用）
  enum :severity, {
    info: 0,       # 情報（青）
    warning: 1,    # 警告（黄）
    critical: 2    # 重要（赤）
  }

  # バリデーション
  validates :title, presence: true, length: { maximum: 100 }
  validates :body, presence: true, length: { maximum: 1000 }
  validates :published_at, presence: true, if: :published?
  validates :display_order, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :expires_at_after_published_at

  # スコープ
  scope :active, -> {
    where(status: :published)
      .where('published_at <= ?', Time.current)
      .where('expires_at IS NULL OR expires_at > ?', Time.current)
      .order(display_order: :asc, published_at: :desc)
  }

  scope :by_severity, ->(severity) { where(severity: severity) }
  scope :recent, -> { order(created_at: :desc) }

  private

  def expires_at_after_published_at
    return if expires_at.blank? || published_at.blank?

    if expires_at <= published_at
      errors.add(:expires_at, 'は公開開始日時より後に設定してください')
    end
  end
end
```

---

#### 3-2. Admin::AnnouncementsController

**ルーティング**:
```ruby
# config/routes.rb
namespace :admin do
  resources :announcements do
    member do
      get :preview
      patch :publish
      patch :archive
    end
  end
end
```

**コントローラー**:
```ruby
# app/controllers/admin/announcements_controller.rb
module Admin
  class AnnouncementsController < Admin::BaseController
    before_action :set_announcement, only: [:show, :edit, :update, :destroy, :preview, :publish, :archive]

    def index
      @q = Announcement.ransack(params[:q])
      @announcements = @q.result.includes(:author).recent.page(params[:page])

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
        redirect_to admin_announcement_path(@announcement), notice: 'アナウンスを作成しました。'
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
        redirect_to admin_announcement_path(@announcement), notice: 'アナウンスを更新しました。'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @announcement

      @announcement.update(status: :archived)
      redirect_to admin_announcements_path, notice: 'アナウンスをアーカイブしました。'
    end

    def preview
      authorize @announcement
      render layout: false
    end

    def publish
      authorize @announcement

      @announcement.published_at ||= Time.current
      @announcement.status = :published

      if @announcement.save
        redirect_to admin_announcement_path(@announcement), notice: 'アナウンスを公開しました。'
      else
        redirect_to admin_announcement_path(@announcement), alert: 'アナウンスの公開に失敗しました。'
      end
    end

    def archive
      authorize @announcement

      @announcement.update(status: :archived)
      redirect_to admin_announcement_path(@announcement), notice: 'アナウンスをアーカイブしました。'
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

**ベースコントローラー**:
```ruby
# app/controllers/admin/base_controller.rb
module Admin
  class BaseController < ApplicationController
    before_action :require_admin!

    layout 'admin'

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

---

#### 3-3. AnnouncementPolicy

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

  def update?
    user.admin?
  end

  def destroy?
    user.admin?
  end

  def preview?
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

### 4. 管理者ダッシュボード

#### 4-1. 概要

**URL**: `/admin`

**表示内容**:
- システム統計
  - 総ユーザー数
  - 総カルテ数
  - アクティブなアナウンス数
  - 有効な紹介コード数
- クイックリンク
  - ユーザー管理
  - アナウンス管理
  - 紹介コード管理

---

#### 4-2. Admin::DashboardController

```ruby
# app/controllers/admin/dashboard_controller.rb
module Admin
  class DashboardController < Admin::BaseController
    def index
      @total_users = User.count
      @total_records = MedicalRecord.count
      @active_announcements = Announcement.active.count
      @active_invitation_codes = InvitationCode.active.count

      # 最近のユーザー登録
      @recent_users = User.order(created_at: :desc).limit(5)
    end
  end
end
```

---

### 5. ユーザー管理機能

#### 5-1. Admin::UsersController

**機能**:
- ユーザー一覧（検索・フィルタ）
- ユーザー詳細
- 権限変更（一般ユーザー ↔ 管理者）
- アカウント停止/有効化

```ruby
# app/controllers/admin/users_controller.rb
module Admin
  class UsersController < Admin::BaseController
    before_action :set_user, only: [:show, :edit, :update, :toggle_role, :toggle_active]

    def index
      @q = User.ransack(params[:q])
      @users = @q.result.order(created_at: :desc).page(params[:page])

      authorize User
    end

    def show
      authorize @user
    end

    def toggle_role
      authorize @user

      new_role = @user.admin? ? :user : :admin

      if @user.update(role: new_role)
        redirect_to admin_user_path(@user), notice: "ユーザーの権限を#{@user.role_i18n}に変更しました。"
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

---

### マイルストーン達成条件（Phase 6-A）

- [ ] Userモデルにroleカラム追加完了
- [ ] Pundit導入・基本ポリシー実装完了
- [ ] ホームページ作成完了
- [ ] Announcementモデル実装完了
- [ ] Admin::AnnouncementsController実装完了
- [ ] アナウンス表示機能（ユーザー側）完了
- [ ] 管理者ダッシュボード実装完了
- [ ] ユーザー管理機能実装完了
- [ ] RSpecテスト全て通過（カバレッジ80%以上）
- [ ] System Spec完了

---

## Phase 6-B: 紹介制度実装（3.5-5.5日）

### 目標
会員登録を紹介制にして、不特定多数の登録を防ぐ。

---

### 1. InvitationCodeモデル

**マイグレーション**:
```ruby
rails g model InvitationCode \
  code:string \
  created_by:references \
  used_by:references \
  used_at:datetime \
  expires_at:datetime \
  max_uses:integer \
  current_uses:integer \
  status:integer

# db/migrate/YYYYMMDDHHMMSS_create_invitation_codes.rb
class CreateInvitationCodes < ActiveRecord::Migration[7.2]
  def change
    create_table :invitation_codes do |t|
      t.string :code, null: false, index: { unique: true }, limit: 12
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :used_by, foreign_key: { to_table: :users }
      t.datetime :used_at
      t.datetime :expires_at
      t.integer :max_uses, default: 1, null: false
      t.integer :current_uses, default: 0, null: false
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    add_index :invitation_codes, :status
    add_index :invitation_codes, :expires_at
  end
end
```

**モデル**:
```ruby
# app/models/invitation_code.rb
class InvitationCode < ApplicationRecord
  belongs_to :created_by, class_name: 'User'
  belongs_to :used_by, class_name: 'User', optional: true

  # ステータス管理
  enum :status, {
    active: 0,    # 有効
    used: 1,      # 使用済み
    expired: 2,   # 期限切れ
    revoked: 3    # 無効化
  }

  # バリデーション
  validates :code, presence: true, uniqueness: true, length: { is: 12 }
  validates :max_uses, numericality: { only_integer: true, greater_than: 0 }
  validates :current_uses, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # スコープ
  scope :active, -> {
    where(status: :active)
      .where('expires_at IS NULL OR expires_at > ?', Time.current)
      .where('current_uses < max_uses')
  }

  scope :recent, -> { order(created_at: :desc) }

  # コールバック
  before_validation :generate_code, on: :create
  before_validation :set_default_expires_at, on: :create

  # コード使用
  def use!(user)
    return false unless can_use?

    transaction do
      self.current_uses += 1
      self.used_by = user if max_uses == 1
      self.used_at = Time.current if current_uses == max_uses
      self.status = :used if current_uses >= max_uses
      save!
    end
  end

  # 使用可能判定
  def can_use?
    active? &&
    (expires_at.nil? || expires_at > Time.current) &&
    current_uses < max_uses
  end

  # 期限切れチェック
  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  private

  def generate_code
    return if code.present?

    loop do
      self.code = SecureRandom.alphanumeric(12).upcase
      break unless InvitationCode.exists?(code: code)
    end
  end

  def set_default_expires_at
    self.expires_at ||= 30.days.from_now
  end
end
```

---

### 2. 会員登録フロー変更

#### 2-1. Devise設定拡張

**コントローラー**:
```ruby
# app/controllers/users/registrations_controller.rb
class Users::RegistrationsController < Devise::RegistrationsController
  before_action :validate_invitation_code, only: [:create]

  private

  def validate_invitation_code
    code = params[:user][:invitation_code]

    if code.blank?
      flash[:alert] = '紹介コードを入力してください。'
      redirect_to new_user_registration_path and return
    end

    @invitation_code = InvitationCode.find_by(code: code)

    unless @invitation_code&.can_use?
      flash[:alert] = '紹介コードが無効です。'
      redirect_to new_user_registration_path and return
    end
  end

  def create
    super do |user|
      if user.persisted? && @invitation_code
        @invitation_code.use!(user)
      end
    end
  end

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation, :invitation_code)
  end
end
```

**ルーティング**:
```ruby
# config/routes.rb
devise_for :users, controllers: {
  registrations: 'users/registrations'
}
```

---

#### 2-2. 会員登録ビュー更新

```erb
<!-- app/views/devise/registrations/new.html.erb -->
<div class="container mx-auto max-w-md px-4 py-8">
  <div class="card bg-base-100 shadow-xl">
    <div class="card-body">
      <h2 class="card-title text-2xl mb-6">会員登録</h2>

      <%= form_for(resource, as: resource_name, url: registration_path(resource_name)) do |f| %>
        <%= render "devise/shared/error_messages", resource: resource %>

        <!-- 紹介コード（必須） -->
        <div class="form-control mb-4">
          <%= f.label :invitation_code, "紹介コード（必須）", class: "label" %>
          <%= f.text_field :invitation_code,
                           class: "input input-bordered w-full",
                           placeholder: "XXXXXXXXXXXX",
                           maxlength: 12,
                           required: true,
                           autofocus: true %>
          <label class="label">
            <span class="label-text-alt">12文字の紹介コードを入力してください</span>
          </label>
        </div>

        <!-- メールアドレス -->
        <div class="form-control mb-4">
          <%= f.label :email, "メールアドレス", class: "label" %>
          <%= f.email_field :email,
                            class: "input input-bordered w-full",
                            autocomplete: "email",
                            required: true %>
        </div>

        <!-- パスワード -->
        <div class="form-control mb-4">
          <%= f.label :password, "パスワード", class: "label" %>
          <%= f.password_field :password,
                               class: "input input-bordered w-full",
                               autocomplete: "new-password",
                               minlength: 6,
                               required: true %>
          <label class="label">
            <span class="label-text-alt">6文字以上</span>
          </label>
        </div>

        <!-- パスワード確認 -->
        <div class="form-control mb-6">
          <%= f.label :password_confirmation, "パスワード確認", class: "label" %>
          <%= f.password_field :password_confirmation,
                               class: "input input-bordered w-full",
                               autocomplete: "new-password",
                               required: true %>
        </div>

        <!-- 登録ボタン -->
        <div class="form-control">
          <%= f.submit "登録する", class: "btn btn-primary w-full" %>
        </div>
      <% end %>

      <!-- ログインリンク -->
      <div class="divider"></div>
      <div class="text-center">
        <%= link_to "すでにアカウントをお持ちの方", new_session_path(resource_name), class: "link link-primary" %>
      </div>
    </div>
  </div>
</div>
```

---

### 3. 管理者：紹介コード管理

#### 3-1. Admin::InvitationCodesController

```ruby
# app/controllers/admin/invitation_codes_controller.rb
module Admin
  class InvitationCodesController < Admin::BaseController
    before_action :set_invitation_code, only: [:show, :revoke]

    def index
      @q = InvitationCode.ransack(params[:q])
      @invitation_codes = @q.result.includes(:created_by, :used_by).recent.page(params[:page])

      authorize InvitationCode
    end

    def show
      authorize @invitation_code
    end

    def new
      @invitation_code = InvitationCode.new
      authorize @invitation_code
    end

    def create
      @invitation_code = InvitationCode.new(invitation_code_params)
      @invitation_code.created_by = current_user

      authorize @invitation_code

      if @invitation_code.save
        redirect_to admin_invitation_code_path(@invitation_code), notice: '紹介コードを作成しました。'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def bulk_create
      authorize InvitationCode

      count = params[:count].to_i
      count = 1 if count < 1
      count = 100 if count > 100

      codes = []
      count.times do
        code = InvitationCode.create!(
          created_by: current_user,
          max_uses: params[:max_uses]&.to_i || 1,
          expires_at: params[:expires_at].present? ? Time.zone.parse(params[:expires_at]) : 30.days.from_now
        )
        codes << code
      end

      respond_to do |format|
        format.html { redirect_to admin_invitation_codes_path, notice: "#{count}件の紹介コードを作成しました。" }
        format.csv do
          send_data generate_csv(codes),
                    filename: "invitation_codes_#{Time.current.strftime('%Y%m%d%H%M%S')}.csv",
                    type: 'text/csv; charset=utf-8'
        end
      end
    end

    def revoke
      authorize @invitation_code

      @invitation_code.update(status: :revoked)
      redirect_to admin_invitation_codes_path, notice: '紹介コードを無効化しました。'
    end

    private

    def set_invitation_code
      @invitation_code = InvitationCode.find(params[:id])
    end

    def invitation_code_params
      params.require(:invitation_code).permit(:max_uses, :expires_at)
    end

    def generate_csv(codes)
      CSV.generate(headers: true, encoding: Encoding::UTF_8) do |csv|
        csv << ['紹介コード', '有効期限', '最大使用回数']

        codes.each do |code|
          csv << [
            code.code,
            code.expires_at&.strftime('%Y/%m/%d %H:%M'),
            code.max_uses
          ]
        end
      end
    end
  end
end
```

---

### マイルストーン達成条件（Phase 6-B）

- [ ] InvitationCodeモデル実装完了
- [ ] 会員登録フロー変更完了
- [ ] 紹介コードバリデーション実装完了
- [ ] Admin::InvitationCodesController実装完了
- [ ] 紹介コード一括生成機能完了
- [ ] CSV出力機能完了
- [ ] RSpecテスト全て通過（カバレッジ80%以上）
- [ ] System Spec完了（会員登録フロー）

---

## Phase 6-C: UI/UX改善（1.5-2.5日）

### 目標
ユーザー体験向上とナビゲーション改善。

---

### 1. ログインページUI改善

**実装内容**:
- Tailwind CSSによるモダンなデザイン
- レスポンシブ対応
- エラーメッセージの明確化

```erb
<!-- app/views/devise/sessions/new.html.erb -->
<div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 px-4">
  <div class="card bg-base-100 shadow-2xl w-full max-w-md">
    <div class="card-body">
      <!-- ロゴ・タイトル -->
      <div class="text-center mb-6">
        <h1 class="text-3xl font-bold text-primary">電子カルテアプリ</h1>
        <p class="text-sm text-gray-600 mt-2">アートメイク施術者向け管理システム</p>
      </div>

      <%= form_for(resource, as: resource_name, url: session_path(resource_name)) do |f| %>
        <!-- エラーメッセージ -->
        <% if flash[:alert] %>
          <div class="alert alert-error mb-4">
            <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current flex-shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <span><%= flash[:alert] %></span>
          </div>
        <% end %>

        <!-- メールアドレス -->
        <div class="form-control mb-4">
          <%= f.label :email, "メールアドレス", class: "label" %>
          <%= f.email_field :email,
                            class: "input input-bordered w-full",
                            autocomplete: "email",
                            autofocus: true,
                            required: true,
                            placeholder: "example@example.com" %>
        </div>

        <!-- パスワード -->
        <div class="form-control mb-4">
          <%= f.label :password, "パスワード", class: "label" %>
          <%= f.password_field :password,
                               class: "input input-bordered w-full",
                               autocomplete: "current-password",
                               required: true,
                               placeholder: "••••••••" %>
        </div>

        <!-- ログイン保持 -->
        <% if devise_mapping.rememberable? %>
          <div class="form-control mb-6">
            <label class="label cursor-pointer justify-start gap-2">
              <%= f.check_box :remember_me, class: "checkbox checkbox-primary" %>
              <span class="label-text">ログイン状態を保持する</span>
            </label>
          </div>
        <% end %>

        <!-- ログインボタン -->
        <div class="form-control">
          <%= f.submit "ログイン", class: "btn btn-primary w-full text-lg" %>
        </div>
      <% end %>

      <!-- リンク -->
      <div class="divider"></div>
      <div class="flex flex-col gap-2 text-center text-sm">
        <%= link_to "パスワードをお忘れの方", new_password_path(resource_name), class: "link link-primary" %>
        <%= link_to "新規登録はこちら", new_registration_path(resource_name), class: "link link-accent" %>
      </div>
    </div>
  </div>
</div>
```

---

### 2. Googleログイン削除

**実施内容**:

1. **Gemfile**:
```ruby
# gem 'omniauth-google-oauth2' # 削除
```

2. **マイグレーション**:
```ruby
rails g migration RemoveOmniauthFromUsers provider uid

class RemoveOmniauthFromUsers < ActiveRecord::Migration[7.2]
  def change
    remove_column :users, :provider, :string
    remove_column :users, :uid, :string
  end
end
```

3. **Devise設定**:
```ruby
# config/initializers/devise.rb
# config.omniauth :google_oauth2, ... # 削除
```

4. **Userモデル**:
```ruby
# app/models/user.rb
# devise :omniauthable, omniauth_providers: [:google_oauth2] # 削除
```

5. **ビュー削除**:
```bash
# Googleログインボタンの削除
# app/views/devise/sessions/new.html.erb
# app/views/devise/registrations/new.html.erb
```

---

### マイルストーン達成条件（Phase 6-C）

- [ ] ホームページ作成完了（Phase 6-Aで実装済み）
- [ ] ログインページUI改善完了
- [ ] Googleログイン削除完了
- [ ] ヘッダーロゴリンク修正完了（root_pathへ）
- [ ] レスポンシブ対応確認完了
- [ ] System Spec完了（ナビゲーション確認）

---

## Phase 6-D: 利用規約整備（1.5-3日）

### 目標
法的コンプライアンスとユーザーへの情報提供。

---

### 1. 利用規約・プライバシーポリシーページ

**ルーティング**:
```ruby
# config/routes.rb
get '/terms', to: 'pages#terms'
get '/privacy', to: 'pages#privacy'
```

**コントローラー**:
```ruby
# app/controllers/pages_controller.rb
class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:terms, :privacy]

  def terms
  end

  def privacy
  end
end
```

**ビュー**:
```erb
<!-- app/views/pages/terms.html.erb -->
<div class="container mx-auto px-4 py-8 max-w-4xl">
  <h1 class="text-3xl font-bold mb-6">利用規約</h1>

  <div class="prose max-w-none">
    <!-- 利用規約の内容（別途相談） -->
    <h2>第1条（適用）</h2>
    <p>本規約は、本サービスの利用条件を定めるものです。</p>

    <h2>第2条（サービス内容）</h2>
    <p>本サービスは、アートメイク施術者向けの電子カルテ管理システムです。</p>

    <!-- ... 詳細は別途相談 ... -->
  </div>
</div>
```

---

### 2. 会員登録時の同意機能

**マイグレーション**:
```ruby
rails g migration AddTermsAgreedAtToUsers terms_agreed_at:datetime

class AddTermsAgreedAtToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :terms_agreed_at, :datetime
    add_index :users, :terms_agreed_at
  end
end
```

**Userモデル**:
```ruby
# app/models/user.rb
validates :terms_agreed_at, presence: true, on: :create

def agree_to_terms!
  update(terms_agreed_at: Time.current)
end
```

**会員登録ビュー**:
```erb
<!-- 利用規約同意チェックボックス -->
<div class="form-control mb-6">
  <label class="label cursor-pointer justify-start gap-2">
    <%= f.check_box :terms_agreement,
                     class: "checkbox checkbox-primary",
                     required: true %>
    <span class="label-text">
      <%= link_to "利用規約", terms_path, target: "_blank", class: "link link-primary" %>
      および
      <%= link_to "プライバシーポリシー", privacy_path, target: "_blank", class: "link link-primary" %>
      に同意します（必須）
    </span>
  </label>
</div>
```

**コントローラー**:
```ruby
# app/controllers/users/registrations_controller.rb
def create
  super do |user|
    if user.persisted?
      user.agree_to_terms! if params[:user][:terms_agreement] == '1'
      @invitation_code&.use!(user)
    end
  end
end
```

---

### 3. アプリ仕様注意書き（別途相談）

**内容案**:
- 施術記録の法的責任範囲
- データ保存期間
- バックアップ推奨頻度
- 医療記録としての扱い
- その他コンプライアンス関連

**表示場所**:
- ホームページに「ご利用にあたって」セクション
- または専用ページ `/guidelines`

---

### マイルストーン達成条件（Phase 6-D）

- [ ] 利用規約ページ作成完了
- [ ] プライバシーポリシーページ作成完了
- [ ] 会員登録時の同意機能実装完了
- [ ] terms_agreed_atカラム追加完了
- [ ] アプリ仕様注意書き作成完了（内容相談後）
- [ ] System Spec完了（同意フロー確認）

---

## 📊 Phase 6全体の成功基準

### 機能面
- [ ] 権限管理（RBAC）完成
- [ ] アナウンス機能完成
- [ ] 紹介制度完成
- [ ] ホームページ完成
- [ ] 利用規約整備完成

### 品質面
- [ ] テストカバレッジ 80%以上維持
- [ ] RuboCop違反 0件
- [ ] Brakeman警告 0件
- [ ] 全E2Eテストパス

### セキュリティ面
- [ ] 管理者権限の厳格な制御
- [ ] 紹介コードのセキュアな生成
- [ ] 利用規約同意の記録

---

## 📝 確認事項・相談事項

### 即決可能な項目

1. **実装順序**: Phase 6-A → 6-B → 6-C → 6-D でOK？
2. **管理者UI**: 独自実装（Tailwind CSS統一）でOK？
3. **紹介コード仕様**:
   - 有効期限: デフォルト30日でOK？
   - 最大使用回数: デフォルト1回でOK？
   - コード形式: 12文字の大文字英数字でOK？

### 別途相談が必要な項目

- 利用規約の詳細内容
- プライバシーポリシーの詳細内容
- アプリ仕様注意書きの内容
- 施術記録の法的責任範囲
- データ保存期間・バックアップ推奨頻度

---

**次のステップ**: ユーザーからの確認・相談事項への回答を待ち、Phase 6-A実装開始

**作成者**: Claude
**最終更新**: 2025-10-20

# Phase 6-B-2 実装計画: お問い合わせ機能

**作成日**: 2025-10-21
**実装予定期間**: 2-3日
**目標**: ユーザーと管理者間でアプリ内完結のお問い合わせ機能を実装

---

## 📋 概要

### 目的

ユーザーからのお問い合わせを管理者が確認・返信できる機能を実装します。メール送信は行わず、アプリ内で完結するシンプルなメッセージング機能です。

### ユースケース

#### ユーザー側
- システムの使い方について質問したい
- 不具合を報告したい
- 機能改善の要望を送りたい
- 管理者からの返信を確認したい

#### 管理者側
- ユーザーからのお問い合わせを一覧表示
- お問い合わせの内容を確認
- ユーザーに返信
- ステータス管理（未対応/対応中/完了）

---

## 🎯 機能要件

### 1. お問い合わせ作成（ユーザー）

**画面**: `/inquiries/new`

**入力項目**:
- 件名（必須、100文字以内）
- 本文（必須、2000文字以内）

**バリデーション**:
- 件名・本文の存在確認
- 文字数制限チェック

**処理**:
- お問い合わせ作成（status: open）
- 初回メッセージを自動作成
- リダイレクト: `/inquiries/:id`（詳細画面）

---

### 2. お問い合わせ一覧（ユーザー）

**画面**: `/inquiries`

**表示内容**:
- 自分が作成したお問い合わせのみ表示
- 件名
- ステータス（未対応/対応中/完了）
- 最終更新日時
- 未読メッセージがある場合はバッジ表示（オプション）

**ソート**:
- デフォルト: 更新日時降順

**ページネーション**:
- 20件/ページ

---

### 3. お問い合わせ詳細（ユーザー）

**画面**: `/inquiries/:id`

**表示内容**:
- 件名
- ステータス
- メッセージ一覧（スレッド形式、時系列順）
  - 送信者（自分 or 管理者）
  - メッセージ本文
  - 送信日時

**機能**:
- 返信フォーム（ステータスがclosedでない場合のみ）
- 返信ボタン

**アクセス制御**:
- 自分のお問い合わせのみ閲覧可能

---

### 4. お問い合わせ返信（ユーザー）

**画面**: `/inquiries/:id`（詳細画面内）

**入力項目**:
- 本文（必須、2000文字以内）

**処理**:
- InquiryMessageレコード作成
- Inquiryのupdated_at更新
- リダイレクト: `/inquiries/:id`

---

### 5. お問い合わせ一覧（管理者）

**画面**: `/admin/inquiries`

**表示内容**:
- 全ユーザーのお問い合わせ
- ユーザー名（メールアドレス）
- 件名
- ステータス
- 最終更新日時

**フィルタ**:
- ステータス（全て/未対応/対応中/完了）
- ユーザー検索（メールアドレス部分一致）

**ソート**:
- デフォルト: 更新日時降順

**ページネーション**:
- 30件/ページ

---

### 6. お問い合わせ詳細（管理者）

**画面**: `/admin/inquiries/:id`

**表示内容**:
- ユーザー情報（名前、メールアドレス）
- 件名
- ステータス
- メッセージ一覧（スレッド形式）

**機能**:
- 返信フォーム
- ステータス変更ボタン（未対応→対応中→完了）

---

### 7. お問い合わせ返信（管理者）

**画面**: `/admin/inquiries/:id`（詳細画面内）

**入力項目**:
- 本文（必須、2000文字以内）
- ステータス変更（オプション）

**処理**:
- InquiryMessageレコード作成
- ステータス更新（指定された場合）
- Inquiryのupdated_at更新
- リダイレクト: `/admin/inquiries/:id`

---

### 8. ステータス変更（管理者）

**画面**: `/admin/inquiries/:id`（詳細画面内）

**ステータス遷移**:
```
open（未対応）
  ↓
in_progress（対応中）
  ↓
closed（完了）
```

**処理**:
- Inquiryのステータス更新
- リダイレクト: `/admin/inquiries/:id`

---

## 🗄️ データモデル

### Inquiry（お問い合わせ）

| カラム | 型 | 制約 | 説明 |
|--------|-----|------|------|
| id | bigint | PK | |
| user_id | bigint | FK, NOT NULL | 作成者（ユーザー） |
| subject | string | NOT NULL | 件名（100文字以内） |
| status | integer | NOT NULL, default: 0 | ステータス（enum） |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

**インデックス**:
- `user_id`
- `status`
- `updated_at`（ソート用）

**enum定義**:
```ruby
enum :status, {
  open: 0,         # 未対応
  in_progress: 1,  # 対応中
  closed: 2        # 完了
}
```

**アソシエーション**:
```ruby
belongs_to :user
has_many :inquiry_messages, dependent: :destroy
```

**バリデーション**:
```ruby
validates :subject, presence: true, length: { maximum: 100 }
validates :status, presence: true
```

**スコープ**:
```ruby
scope :recent, -> { order(updated_at: :desc) }
scope :by_status, ->(status) { where(status: status) if status.present? }
```

---

### InquiryMessage（お問い合わせメッセージ）

| カラム | 型 | 制約 | 説明 |
|--------|-----|------|------|
| id | bigint | PK | |
| inquiry_id | bigint | FK, NOT NULL | お問い合わせ |
| user_id | bigint | FK, NOT NULL | 送信者（ユーザーまたは管理者） |
| body | text | NOT NULL | 本文（2000文字以内） |
| created_at | datetime | NOT NULL | 送信日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

**インデックス**:
- `inquiry_id`
- `user_id`
- `created_at`（時系列表示用）

**アソシエーション**:
```ruby
belongs_to :inquiry, touch: true  # 親のupdated_atを更新
belongs_to :user
```

**バリデーション**:
```ruby
validates :body, presence: true, length: { maximum: 2000 }
```

**スコープ**:
```ruby
scope :chronological, -> { order(created_at: :asc) }
```

---

## 🛠️ 実装手順（TDD）

### Step 1: モデル実装（0.5日）

#### 1-1. マイグレーション作成

```bash
# Inquiryテーブル
rails g model Inquiry user:references subject:string status:integer

# InquiryMessageテーブル
rails g model InquiryMessage inquiry:references user:references body:text
```

**マイグレーション編集**:
```ruby
# db/migrate/YYYYMMDDHHMMSS_create_inquiries.rb
class CreateInquiries < ActiveRecord::Migration[7.2]
  def change
    create_table :inquiries do |t|
      t.references :user, null: false, foreign_key: true
      t.string :subject, null: false, limit: 100
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :inquiries, :status
    add_index :inquiries, :updated_at
  end
end

# db/migrate/YYYYMMDDHHMMSS_create_inquiry_messages.rb
class CreateInquiryMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :inquiry_messages do |t|
      t.references :inquiry, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false, limit: 2000

      t.timestamps
    end

    add_index :inquiry_messages, :created_at
  end
end
```

#### 1-2. モデル実装

**spec/models/inquiry_spec.rb**:
```ruby
require 'rails_helper'

RSpec.describe Inquiry, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:inquiry_messages).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:subject) }
    it { should validate_length_of(:subject).is_at_most(100) }
    it { should validate_presence_of(:status) }
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(open: 0, in_progress: 1, closed: 2) }
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let!(:old_inquiry) { create(:inquiry, user: user, updated_at: 2.days.ago) }
    let!(:new_inquiry) { create(:inquiry, user: user, updated_at: 1.day.ago) }

    describe '.recent' do
      it '更新日時の降順で取得できる' do
        expect(Inquiry.recent).to eq([new_inquiry, old_inquiry])
      end
    end

    describe '.by_status' do
      let!(:open_inquiry) { create(:inquiry, user: user, status: :open) }
      let!(:closed_inquiry) { create(:inquiry, user: user, status: :closed) }

      it '指定したステータスのみ取得できる' do
        expect(Inquiry.by_status(:open)).to eq([open_inquiry])
      end

      it 'ステータスがnilの場合は全て取得できる' do
        expect(Inquiry.by_status(nil).count).to eq(4)
      end
    end
  end
end
```

**spec/models/inquiry_message_spec.rb**:
```ruby
require 'rails_helper'

RSpec.describe InquiryMessage, type: :model do
  describe 'associations' do
    it { should belong_to(:inquiry) }
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:body) }
    it { should validate_length_of(:body).is_at_most(2000) }
  end

  describe 'touch inquiry' do
    let(:user) { create(:user) }
    let(:inquiry) { create(:inquiry, user: user) }

    it 'メッセージ作成時にinquiryのupdated_atが更新される' do
      expect {
        create(:inquiry_message, inquiry: inquiry, user: user)
      }.to change { inquiry.reload.updated_at }
    end
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let(:inquiry) { create(:inquiry, user: user) }
    let!(:old_message) { create(:inquiry_message, inquiry: inquiry, user: user, created_at: 2.hours.ago) }
    let!(:new_message) { create(:inquiry_message, inquiry: inquiry, user: user, created_at: 1.hour.ago) }

    describe '.chronological' do
      it '作成日時の昇順で取得できる' do
        expect(inquiry.inquiry_messages.chronological).to eq([old_message, new_message])
      end
    end
  end
end
```

**app/models/inquiry.rb**:
```ruby
class Inquiry < ApplicationRecord
  belongs_to :user
  has_many :inquiry_messages, dependent: :destroy

  validates :subject, presence: true, length: { maximum: 100 }
  validates :status, presence: true

  enum :status, {
    open: 0,
    in_progress: 1,
    closed: 2
  }

  scope :recent, -> { order(updated_at: :desc) }
  scope :by_status, ->(status) { where(status: status) if status.present? }
end
```

**app/models/inquiry_message.rb**:
```ruby
class InquiryMessage < ApplicationRecord
  belongs_to :inquiry, touch: true
  belongs_to :user

  validates :body, presence: true, length: { maximum: 2000 }

  scope :chronological, -> { order(created_at: :asc) }
end
```

#### 1-3. FactoryBot定義

**spec/factories/inquiries.rb**:
```ruby
FactoryBot.define do
  factory :inquiry do
    association :user
    subject { 'お問い合わせ件名' }
    status { :open }

    trait :in_progress do
      status { :in_progress }
    end

    trait :closed do
      status { :closed }
    end

    trait :with_messages do
      after(:create) do |inquiry|
        create_list(:inquiry_message, 3, inquiry: inquiry, user: inquiry.user)
      end
    end
  end
end
```

**spec/factories/inquiry_messages.rb**:
```ruby
FactoryBot.define do
  factory :inquiry_message do
    association :inquiry
    association :user
    body { 'お問い合わせ本文です。' }
  end
end
```

---

### Step 2: ユーザー側コントローラー実装（0.5日）

#### 2-1. ルーティング

**config/routes.rb**:
```ruby
resources :inquiries, only: [:index, :show, :new, :create] do
  resources :messages, only: [:create], controller: 'inquiry_messages'
end
```

#### 2-2. Request Spec

**spec/requests/inquiries_spec.rb**:
```ruby
require 'rails_helper'

RSpec.describe 'Inquiries', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  before do
    sign_in user
  end

  describe 'GET /inquiries' do
    let!(:my_inquiry) { create(:inquiry, user: user) }
    let!(:other_inquiry) { create(:inquiry, user: other_user) }

    it '自分のお問い合わせのみ表示される' do
      get inquiries_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(my_inquiry.subject)
      expect(response.body).not_to include(other_inquiry.subject)
    end
  end

  describe 'GET /inquiries/:id' do
    let(:inquiry) { create(:inquiry, :with_messages, user: user) }

    it 'お問い合わせ詳細が表示される' do
      get inquiry_path(inquiry)
      expect(response).to have_http_status(:ok)
    end

    context '他人のお問い合わせ' do
      let(:other_inquiry) { create(:inquiry, user: other_user) }

      it 'アクセスできない' do
        expect {
          get inquiry_path(other_inquiry)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'GET /inquiries/new' do
    it 'お問い合わせ作成フォームが表示される' do
      get new_inquiry_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /inquiries' do
    let(:valid_params) do
      {
        inquiry: {
          subject: 'テストお問い合わせ',
          body: 'これはテスト本文です。'
        }
      }
    end

    it 'お問い合わせが作成される' do
      expect {
        post inquiries_path, params: valid_params
      }.to change(Inquiry, :count).by(1)
        .and change(InquiryMessage, :count).by(1)

      inquiry = Inquiry.last
      expect(inquiry.subject).to eq('テストお問い合わせ')
      expect(inquiry.status).to eq('open')
      expect(inquiry.inquiry_messages.first.body).to eq('これはテスト本文です。')

      expect(response).to redirect_to(inquiry_path(inquiry))
    end

    context '無効なパラメータ' do
      let(:invalid_params) do
        { inquiry: { subject: '', body: '' } }
      end

      it 'お問い合わせが作成されない' do
        expect {
          post inquiries_path, params: invalid_params
        }.not_to change(Inquiry, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'POST /inquiries/:id/messages' do
    let(:inquiry) { create(:inquiry, user: user) }
    let(:valid_params) do
      { inquiry_message: { body: '返信メッセージです。' } }
    end

    it 'メッセージが追加される' do
      expect {
        post inquiry_messages_path(inquiry), params: valid_params
      }.to change(inquiry.inquiry_messages, :count).by(1)

      expect(response).to redirect_to(inquiry_path(inquiry))
    end

    context '完了済みのお問い合わせ' do
      let(:closed_inquiry) { create(:inquiry, :closed, user: user) }

      it 'メッセージを追加できない' do
        expect {
          post inquiry_messages_path(closed_inquiry), params: valid_params
        }.not_to change(InquiryMessage, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
```

#### 2-3. コントローラー実装

**app/controllers/inquiries_controller.rb**:
```ruby
class InquiriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_inquiry, only: [:show]

  def index
    @inquiries = current_user.inquiries.recent.page(params[:page]).per(20)
  end

  def show
    @messages = @inquiry.inquiry_messages.chronological
    @message = @inquiry.inquiry_messages.build
  end

  def new
    @inquiry = current_user.inquiries.build
  end

  def create
    @inquiry = current_user.inquiries.build(inquiry_params.except(:body))

    if @inquiry.save
      # 初回メッセージを作成
      @inquiry.inquiry_messages.create!(
        user: current_user,
        body: inquiry_params[:body]
      )

      redirect_to inquiry_path(@inquiry), notice: 'お問い合わせを送信しました。'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_inquiry
    @inquiry = current_user.inquiries.find(params[:id])
  end

  def inquiry_params
    params.require(:inquiry).permit(:subject, :body)
  end
end
```

**app/controllers/inquiry_messages_controller.rb**:
```ruby
class InquiryMessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_inquiry

  def create
    if @inquiry.closed?
      redirect_to inquiry_path(@inquiry), alert: '完了済みのお問い合わせには返信できません。'
      return
    end

    @message = @inquiry.inquiry_messages.build(message_params)
    @message.user = current_user

    if @message.save
      redirect_to inquiry_path(@inquiry), notice: '返信を送信しました。'
    else
      @messages = @inquiry.inquiry_messages.chronological
      render 'inquiries/show', status: :unprocessable_entity
    end
  end

  private

  def set_inquiry
    @inquiry = current_user.inquiries.find(params[:inquiry_id])
  end

  def message_params
    params.require(:inquiry_message).permit(:body)
  end
end
```

---

### Step 3: 管理者側コントローラー実装（0.5日）

#### 3-1. ルーティング

**config/routes.rb**:
```ruby
namespace :admin do
  resources :inquiries, only: [:index, :show] do
    member do
      patch :update_status
    end
    resources :messages, only: [:create], controller: 'inquiry_messages'
  end
end
```

#### 3-2. Request Spec

**spec/requests/admin/inquiries_spec.rb**:
```ruby
require 'rails_helper'

RSpec.describe 'Admin::Inquiries', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:user) { create(:user) }

  before do
    sign_in admin
  end

  describe 'GET /admin/inquiries' do
    let!(:inquiry1) { create(:inquiry, user: user, status: :open) }
    let!(:inquiry2) { create(:inquiry, user: user, status: :closed) }

    it '全てのお問い合わせが表示される' do
      get admin_inquiries_path
      expect(response).to have_http_status(:ok)
    end

    it 'ステータスでフィルタできる' do
      get admin_inquiries_path, params: { status: 'open' }
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /admin/inquiries/:id' do
    let(:inquiry) { create(:inquiry, :with_messages, user: user) }

    it 'お問い合わせ詳細が表示される' do
      get admin_inquiry_path(inquiry)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /admin/inquiries/:id/messages' do
    let(:inquiry) { create(:inquiry, user: user) }
    let(:valid_params) do
      { inquiry_message: { body: '管理者からの返信です。' } }
    end

    it 'メッセージが追加される' do
      expect {
        post admin_inquiry_messages_path(inquiry), params: valid_params
      }.to change(inquiry.inquiry_messages, :count).by(1)

      message = inquiry.inquiry_messages.last
      expect(message.user).to eq(admin)
      expect(response).to redirect_to(admin_inquiry_path(inquiry))
    end
  end

  describe 'PATCH /admin/inquiries/:id/update_status' do
    let(:inquiry) { create(:inquiry, user: user, status: :open) }

    it 'ステータスが更新される' do
      patch update_status_admin_inquiry_path(inquiry), params: { status: 'in_progress' }
      expect(inquiry.reload.status).to eq('in_progress')
      expect(response).to redirect_to(admin_inquiry_path(inquiry))
    end
  end
end
```

#### 3-3. コントローラー実装

**app/controllers/admin/inquiries_controller.rb**:
```ruby
module Admin
  class InquiriesController < Admin::BaseController
    before_action :set_inquiry, only: [:show, :update_status]

    def index
      @inquiries = Inquiry.includes(:user)
                          .by_status(params[:status])
                          .recent
                          .page(params[:page])
                          .per(30)
    end

    def show
      @messages = @inquiry.inquiry_messages.includes(:user).chronological
      @message = @inquiry.inquiry_messages.build
    end

    def update_status
      if @inquiry.update(status: params[:status])
        redirect_to admin_inquiry_path(@inquiry), notice: 'ステータスを更新しました。'
      else
        redirect_to admin_inquiry_path(@inquiry), alert: 'ステータスの更新に失敗しました。'
      end
    end

    private

    def set_inquiry
      @inquiry = Inquiry.find(params[:id])
    end
  end
end
```

**app/controllers/admin/inquiry_messages_controller.rb**:
```ruby
module Admin
  class InquiryMessagesController < Admin::BaseController
    before_action :set_inquiry

    def create
      @message = @inquiry.inquiry_messages.build(message_params)
      @message.user = current_user

      if @message.save
        redirect_to admin_inquiry_path(@inquiry), notice: '返信を送信しました。'
      else
        @messages = @inquiry.inquiry_messages.includes(:user).chronological
        render 'admin/inquiries/show', status: :unprocessable_entity
      end
    end

    private

    def set_inquiry
      @inquiry = Inquiry.find(params[:inquiry_id])
    end

    def message_params
      params.require(:inquiry_message).permit(:body)
    end
  end
end
```

---

### Step 4: ビュー実装（0.5日）

#### 4-1. ユーザー側ビュー

**app/views/inquiries/index.html.erb**:
```erb
<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
  <div class="mb-8 flex justify-between items-center">
    <div>
      <h1 class="text-3xl font-bold text-gray-900">お問い合わせ</h1>
      <p class="mt-2 text-sm text-gray-600">管理者への質問・要望を送信できます</p>
    </div>
    <%= link_to "新規お問い合わせ", new_inquiry_path, class: "inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700" %>
  </div>

  <% if @inquiries.any? %>
    <div class="bg-white shadow-sm rounded-lg overflow-hidden">
      <ul class="divide-y divide-gray-200">
        <% @inquiries.each do |inquiry| %>
          <li class="hover:bg-gray-50">
            <%= link_to inquiry_path(inquiry), class: "block px-6 py-4" do %>
              <div class="flex items-center justify-between">
                <div class="flex-1 min-w-0">
                  <p class="text-sm font-medium text-gray-900 truncate">
                    <%= inquiry.subject %>
                  </p>
                  <p class="text-sm text-gray-500">
                    <%= inquiry.updated_at.strftime('%Y/%m/%d %H:%M') %>
                  </p>
                </div>
                <div class="ml-4 flex-shrink-0">
                  <%= status_badge(inquiry.status) %>
                </div>
              </div>
            <% end %>
          </li>
        <% end %>
      </ul>
    </div>

    <div class="mt-6">
      <%= paginate @inquiries %>
    </div>
  <% else %>
    <div class="text-center py-12 bg-white rounded-lg shadow-sm">
      <p class="text-gray-500">お問い合わせはまだありません</p>
      <%= link_to "新規お問い合わせ", new_inquiry_path, class: "mt-4 inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700" %>
    </div>
  <% end %>
</div>
```

**app/views/inquiries/new.html.erb**:
```erb
<div class="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
  <h1 class="text-3xl font-bold text-gray-900 mb-8">お問い合わせ</h1>

  <%= form_with model: @inquiry, local: true, class: "space-y-6" do |f| %>
    <div>
      <%= f.label :subject, '件名', class: 'block text-sm font-medium text-gray-700' %>
      <%= f.text_field :subject, class: 'mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500', maxlength: 100 %>
    </div>

    <div>
      <%= f.label :body, '本文', class: 'block text-sm font-medium text-gray-700' %>
      <%= f.text_area :body, rows: 10, class: 'mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500', maxlength: 2000 %>
      <p class="mt-1 text-sm text-gray-500">2000文字以内</p>
    </div>

    <div class="flex gap-4">
      <%= f.submit '送信', class: 'inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700' %>
      <%= link_to 'キャンセル', inquiries_path, class: 'inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50' %>
    </div>
  <% end %>
</div>
```

**app/views/inquiries/show.html.erb**:
```erb
<div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
  <div class="mb-8 flex justify-between items-center">
    <div>
      <h1 class="text-2xl font-bold text-gray-900"><%= @inquiry.subject %></h1>
      <div class="mt-2">
        <%= status_badge(@inquiry.status) %>
      </div>
    </div>
    <%= link_to '一覧に戻る', inquiries_path, class: 'text-blue-600 hover:text-blue-700' %>
  </div>

  <!-- メッセージ一覧 -->
  <div class="space-y-4 mb-8">
    <% @messages.each do |message| %>
      <div class="bg-white rounded-lg shadow-sm p-6 <%= message.user.admin? ? 'border-l-4 border-blue-500' : '' %>">
        <div class="flex items-center justify-between mb-4">
          <div class="flex items-center space-x-2">
            <span class="text-sm font-medium text-gray-900">
              <%= message.user.admin? ? '管理者' : 'あなた' %>
            </span>
          </div>
          <span class="text-sm text-gray-500">
            <%= message.created_at.strftime('%Y/%m/%d %H:%M') %>
          </span>
        </div>
        <div class="text-gray-700 whitespace-pre-wrap">
          <%= message.body %>
        </div>
      </div>
    <% end %>
  </div>

  <!-- 返信フォーム -->
  <% unless @inquiry.closed? %>
    <div class="bg-white rounded-lg shadow-sm p-6">
      <h2 class="text-lg font-medium text-gray-900 mb-4">返信</h2>
      <%= form_with model: @message, url: inquiry_messages_path(@inquiry), local: true do |f| %>
        <div class="mb-4">
          <%= f.text_area :body, rows: 6, class: 'block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500', placeholder: '返信内容を入力してください', maxlength: 2000 %>
        </div>
        <%= f.submit '返信する', class: 'inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700' %>
      <% end %>
    </div>
  <% else %>
    <div class="bg-gray-50 rounded-lg p-6 text-center">
      <p class="text-gray-600">このお問い合わせは完了済みです</p>
    </div>
  <% end %>
</div>
```

#### 4-2. 管理者側ビュー

**app/views/admin/inquiries/index.html.erb**:
```erb
<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
  <h1 class="text-3xl font-bold text-gray-900 mb-8">お問い合わせ管理</h1>

  <!-- ステータスフィルタ -->
  <div class="mb-6">
    <%= form_with url: admin_inquiries_path, method: :get, local: true, class: "flex gap-2" do |f| %>
      <%= f.select :status, options_for_select([['全て', ''], ['未対応', 'open'], ['対応中', 'in_progress'], ['完了', 'closed']], params[:status]), {}, class: 'border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500' %>
      <%= f.submit '絞り込み', class: 'px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700' %>
    <% end %>
  </div>

  <% if @inquiries.any? %>
    <div class="bg-white shadow-sm rounded-lg overflow-hidden">
      <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
          <tr>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">ユーザー</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">件名</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">ステータス</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">更新日時</th>
            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">操作</th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
          <% @inquiries.each do |inquiry| %>
            <tr class="hover:bg-gray-50">
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                <%= inquiry.user.email %>
              </td>
              <td class="px-6 py-4 text-sm text-gray-900">
                <%= inquiry.subject %>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <%= status_badge(inquiry.status) %>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                <%= inquiry.updated_at.strftime('%Y/%m/%d %H:%M') %>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-right text-sm">
                <%= link_to '詳細', admin_inquiry_path(inquiry), class: 'text-blue-600 hover:text-blue-700' %>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>

    <div class="mt-6">
      <%= paginate @inquiries %>
    </div>
  <% else %>
    <div class="text-center py-12 bg-white rounded-lg shadow-sm">
      <p class="text-gray-500">お問い合わせはありません</p>
    </div>
  <% end %>
</div>
```

**app/views/admin/inquiries/show.html.erb**:
```erb
<div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
  <div class="mb-8">
    <div class="flex justify-between items-start mb-4">
      <div>
        <h1 class="text-2xl font-bold text-gray-900"><%= @inquiry.subject %></h1>
        <p class="mt-2 text-sm text-gray-600">
          投稿者: <%= @inquiry.user.email %>
        </p>
      </div>
      <%= link_to '一覧に戻る', admin_inquiries_path, class: 'text-blue-600 hover:text-blue-700' %>
    </div>

    <!-- ステータス変更 -->
    <div class="flex items-center gap-4">
      <%= status_badge(@inquiry.status) %>
      <% unless @inquiry.closed? %>
        <%= form_with url: update_status_admin_inquiry_path(@inquiry), method: :patch, local: true, class: "flex gap-2" do |f| %>
          <%= select_tag :status, options_for_select([['未対応', 'open'], ['対応中', 'in_progress'], ['完了', 'closed']], @inquiry.status), class: 'border-gray-300 rounded-md shadow-sm text-sm' %>
          <%= f.submit 'ステータス変更', class: 'px-3 py-1 bg-gray-600 text-white text-sm rounded-md hover:bg-gray-700' %>
        <% end %>
      <% end %>
    </div>
  </div>

  <!-- メッセージ一覧 -->
  <div class="space-y-4 mb-8">
    <% @messages.each do |message| %>
      <div class="bg-white rounded-lg shadow-sm p-6 <%= message.user.admin? ? 'border-l-4 border-blue-500' : '' %>">
        <div class="flex items-center justify-between mb-4">
          <div class="flex items-center space-x-2">
            <span class="text-sm font-medium text-gray-900">
              <%= message.user.admin? ? "管理者（#{message.user.email}）" : message.user.email %>
            </span>
          </div>
          <span class="text-sm text-gray-500">
            <%= message.created_at.strftime('%Y/%m/%d %H:%M') %>
          </span>
        </div>
        <div class="text-gray-700 whitespace-pre-wrap">
          <%= message.body %>
        </div>
      </div>
    <% end %>
  </div>

  <!-- 返信フォーム -->
  <div class="bg-white rounded-lg shadow-sm p-6">
    <h2 class="text-lg font-medium text-gray-900 mb-4">返信</h2>
    <%= form_with model: @message, url: admin_inquiry_messages_path(@inquiry), local: true do |f| %>
      <div class="mb-4">
        <%= f.text_area :body, rows: 6, class: 'block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500', placeholder: '返信内容を入力してください', maxlength: 2000 %>
      </div>
      <%= f.submit '返信する', class: 'inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700' %>
    <% end %>
  </div>
</div>
```

#### 4-3. ヘルパー

**app/helpers/inquiries_helper.rb**:
```ruby
module InquiriesHelper
  def status_badge(status)
    case status.to_sym
    when :open
      content_tag :span, '未対応', class: 'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800'
    when :in_progress
      content_tag :span, '対応中', class: 'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800'
    when :closed
      content_tag :span, '完了', class: 'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800'
    end
  end
end
```

---

### Step 5: System Spec（0.5日）

**spec/system/inquiries_spec.rb**:
```ruby
require 'rails_helper'

RSpec.describe 'Inquiries', type: :system do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe 'お問い合わせ作成', js: true do
    it 'お問い合わせを作成できる' do
      visit new_inquiry_path

      fill_in '件名', with: 'テストお問い合わせ'
      fill_in '本文', with: 'これはテストの本文です。'
      click_button '送信'

      expect(page).to have_content('お問い合わせを送信しました')
      expect(page).to have_content('テストお問い合わせ')
      expect(page).to have_content('これはテストの本文です。')
    end
  end

  describe 'お問い合わせ一覧', js: true do
    let!(:inquiry) { create(:inquiry, user: user, subject: 'テスト件名') }

    it 'お問い合わせ一覧が表示される' do
      visit inquiries_path

      expect(page).to have_content('テスト件名')
    end
  end

  describe 'お問い合わせ返信', js: true do
    let(:inquiry) { create(:inquiry, :with_messages, user: user) }

    it 'お問い合わせに返信できる' do
      visit inquiry_path(inquiry)

      fill_in 'inquiry_message[body]', with: '追加の質問です。'
      click_button '返信する'

      expect(page).to have_content('返信を送信しました')
      expect(page).to have_content('追加の質問です。')
    end
  end
end
```

**spec/system/admin/inquiries_spec.rb**:
```ruby
require 'rails_helper'

RSpec.describe 'Admin::Inquiries', type: :system do
  let(:admin) { create(:user, :admin) }
  let(:user) { create(:user) }

  before do
    sign_in admin
  end

  describe 'お問い合わせ一覧', js: true do
    let!(:inquiry) { create(:inquiry, user: user) }

    it '全ユーザーのお問い合わせが表示される' do
      visit admin_inquiries_path

      expect(page).to have_content(inquiry.subject)
      expect(page).to have_content(user.email)
    end
  end

  describe 'お問い合わせ返信', js: true do
    let(:inquiry) { create(:inquiry, :with_messages, user: user) }

    it 'お問い合わせに返信できる' do
      visit admin_inquiry_path(inquiry)

      fill_in 'inquiry_message[body]', with: '管理者からの返信です。'
      click_button '返信する'

      expect(page).to have_content('返信を送信しました')
      expect(page).to have_content('管理者からの返信です。')
    end
  end

  describe 'ステータス変更', js: true do
    let(:inquiry) { create(:inquiry, user: user, status: :open) }

    it 'ステータスを変更できる' do
      visit admin_inquiry_path(inquiry)

      select '対応中', from: 'status'
      click_button 'ステータス変更'

      expect(page).to have_content('ステータスを更新しました')
      expect(page).to have_content('対応中')
    end
  end
end
```

---

## 🎨 UI/UX設計

### デザインガイドライン

- **カラースキーム**: 既存の管理画面と統一（Tailwind CSS）
- **レスポンシブ**: モバイル・タブレット・デスクトップ対応
- **アクセシビリティ**: ARIA属性、キーボードナビゲーション対応

### ステータスバッジ

| ステータス | 背景色 | テキスト色 | 表示文言 |
|-----------|--------|-----------|---------|
| open | yellow-100 | yellow-800 | 未対応 |
| in_progress | blue-100 | blue-800 | 対応中 |
| closed | gray-100 | gray-800 | 完了 |

---

## 📊 テスト計画

### テストカバレッジ目標

- **Model Spec**: 100%
- **Request Spec**: 100%
- **System Spec**: 主要機能100%

### テスト項目

#### Model Spec
- [x] アソシエーション
- [x] バリデーション
- [x] enum定義
- [x] スコープ
- [x] touch動作

#### Request Spec（ユーザー側）
- [x] お問い合わせ一覧表示（自分のもののみ）
- [x] お問い合わせ詳細表示
- [x] 他人のお問い合わせへのアクセス拒否
- [x] お問い合わせ作成
- [x] バリデーションエラー
- [x] メッセージ追加
- [x] 完了済みお問い合わせへの返信拒否

#### Request Spec（管理者側）
- [x] お問い合わせ一覧表示（全ユーザー）
- [x] ステータスフィルタ
- [x] お問い合わせ詳細表示
- [x] メッセージ追加
- [x] ステータス変更

#### System Spec
- [x] お問い合わせ作成フロー
- [x] お問い合わせ一覧表示
- [x] お問い合わせ返信（ユーザー）
- [x] お問い合わせ返信（管理者）
- [x] ステータス変更

---

## 🔒 セキュリティ対策

### アクセス制御

- **ユーザー側**: 自分のお問い合わせのみアクセス可能
- **管理者側**: 全てのお問い合わせにアクセス可能
- **認証**: `authenticate_user!` による認証必須
- **認可**: コントローラーレベルでのスコープ制限

### Mass Assignment対策

- Strong Parameters による許可リスト方式
- `permit`で明示的に許可したパラメータのみ受け入れ

### XSS対策

- ビューでの自動エスケープ（Rails標準）
- `sanitize`ヘルパーは不使用（plain textのみ）

### CSRF対策

- Rails標準のCSRF保護（authenticity_token）

---

## 🚀 デプロイ計画

### マイグレーション実行

```bash
# 本番環境
rails db:migrate RAILS_ENV=production
```

### Railsコンソールでの確認

```ruby
# お問い合わせ数確認
Inquiry.count

# ステータス別集計
Inquiry.group(:status).count
```

---

## 📈 今後の拡張案（Phase 6-B-2以降）

### 優先度: 中

- [ ] **お問い合わせカテゴリー**: 質問/不具合報告/機能要望などの分類
- [ ] **添付ファイル対応**: スクリーンショット添付
- [ ] **お知らせとの連携**: よくあるお問い合わせをお知らせとして公開

### 優先度: 低

- [ ] **メール通知**: 管理者への新規お問い合わせ通知（オプション）
- [ ] **検索機能**: 件名・本文での全文検索
- [ ] **既読/未読管理**: 管理者側の未読表示

---

## ✅ 完了条件

### 機能実装
- [x] Inquiry/InquiryMessageモデル実装
- [x] ユーザー側CRUD実装
- [x] 管理者側CRUD実装
- [x] ビュー実装

### 品質保証
- [x] Model Spec: 100%カバレッジ
- [x] Request Spec: 100%カバレッジ
- [x] System Spec: 主要機能カバー
- [x] RuboCop: 違反なし
- [x] Brakeman: 警告なし

### ドキュメント
- [x] 実装計画書作成（本ドキュメント）
- [ ] 完了報告書作成

---

## 📝 補足事項

### 既存機能への影響

- **影響なし**: 独立した機能として実装
- **ヘッダー追加**: ユーザー側ナビゲーションに「お問い合わせ」リンク追加
- **管理者メニュー追加**: 管理者ナビゲーションに「お問い合わせ管理」リンク追加

### パフォーマンス考慮

- **N+1対策**: `includes`でuser/inquiryを事前ロード
- **ページネーション**: Kaminari使用（20-30件/ページ）
- **インデックス**: user_id, status, updated_at, created_at

---

**実装開始予定**: 次回セッション
**完了予定**: 2-3日後

# Phase 1 実装ガイド

**プロジェクト名**: フリーランス美容施術者向け電子カルテアプリ
**作成日**: 2025-10-12
**バージョン**: 1.0
**言語**: 日本語
**対象**: Phase 1 MVP 開発（Week 3-6）

---

## 1. はじめに

### 1.1 本ドキュメントの目的

本書は、Phase 1（MVP 開発）の実装を段階的に進めるための実践的なガイドです。

**対象読者:**

- 開発者（自分自身）
- 将来のメンテナンス担当者

**記載内容:**

- 週次実装タスク
- TDD 実装フロー
- 具体的なコード例
- トラブルシューティング

### 1.2 Phase 1 の目標

**期間**: Week 3-6（4 週間）

**成果物:**

- ✅ 施術場所管理（CRUD）
- ✅ 患者管理（CRUD + 検索）
- ✅ コストシート管理（CRUD）
- ✅ カルテ管理（CRUD + 動的フォーム + 画像アップロード）
- ✅ タグ機能
- ✅ 検索・フィルタリング

**品質基準:**

- テストカバレッジ: 80%以上
- RuboCop 違反: 0 件
- すべての SystemSpec がパス

---

## 2. 開発環境セットアップ（再確認）

### 2.1 必須確認事項

Phase 1 開始前に以下を確認：

```bash
# Ruby バージョン
ruby -v
# => ruby 3.2.2

# Rails バージョン
rails -v
# => Rails 7.1.x

# PostgreSQL 起動確認
psql --version
# => psql (PostgreSQL) 14.x

# Node.js / Yarn
node -v  # => v18.x
yarn -v  # => 1.22.x

# ImageMagick or libvips
magick -version  # または vips -v
```

### 2.2 データベース作成

```bash
# データベース作成
rails db:create

# 確認
rails db:migrate:status
```

### 2.3 Git 初期化確認

```bash
# ブランチ確認
git branch
# => * main

# Phase 1用ブランチ作成
git checkout -b feature/phase1-setup
```

---

## 3. Week 3-4: 基本 CRUD 実装

### 3.1 Day 1-2: Facility（施術場所）実装

#### 3.1.1 TDD 実装フロー

**Step 1: Model Spec を書く（Red）**

```ruby
# spec/models/facility_spec.rb
require 'rails_helper'

RSpec.describe Facility, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:medical_records).dependent(:restrict_with_error) }
    it { should have_many(:invoices).dependent(:restrict_with_error) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(100) }

    context 'phone format' do
      it 'accepts valid phone format' do
        facility = build(:facility, phone: '03-1234-5678')
        expect(facility).to be_valid
      end

      it 'rejects invalid phone format' do
        facility = build(:facility, phone: 'invalid')
        expect(facility).not_to be_valid
      end
    end

    context 'email format' do
      it 'accepts valid email format' do
        facility = build(:facility, email: 'test@example.com')
        expect(facility).to be_valid
      end

      it 'rejects invalid email format' do
        facility = build(:facility, email: 'invalid')
        expect(facility).not_to be_valid
      end
    end
  end

  describe 'methods' do
    let(:user) { create(:user) }
    let(:facility) { create(:facility, user: user) }

    describe '#has_records?' do
      context 'when facility has medical records' do
        before { create(:medical_record, facility: facility, user: user) }

        it 'returns true' do
          expect(facility.has_records?).to be true
        end
      end

      context 'when facility has no medical records' do
        it 'returns false' do
          expect(facility.has_records?).to be false
        end
      end
    end

    describe '#total_revenue' do
      before do
        create(:medical_record, facility: facility, user: user,
               treatment_date: Date.today, total_amount: 50000)
        create(:medical_record, facility: facility, user: user,
               treatment_date: Date.today - 1.day, total_amount: 30000)
      end

      it 'returns total revenue without date range' do
        expect(facility.total_revenue).to eq(80000)
      end

      it 'returns total revenue within date range' do
        expect(facility.total_revenue(Date.today, Date.today)).to eq(50000)
      end
    end

    describe '#medical_records_count' do
      before do
        create_list(:medical_record, 3, facility: facility, user: user)
      end

      it 'returns the count of medical records' do
        expect(facility.medical_records_count).to eq(3)
      end
    end
  end
end
```

**Step 2: Model を実装（Green）**

```ruby
# app/models/facility.rb
class Facility < ApplicationRecord
  belongs_to :user
  has_many :medical_records, dependent: :restrict_with_error
  has_many :invoices, dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: 100 }
  validates :phone, format: { with: /\A\d{2,4}-?\d{2,4}-?\d{3,4}\z/, allow_blank: true }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }

  scope :recent, -> { order(created_at: :desc) }
  scope :by_name, -> { order(:name) }

  def has_records?
    medical_records.exists?
  end

  def total_revenue(start_date = nil, end_date = nil)
    records = medical_records
    records = records.where('treatment_date >= ?', start_date) if start_date
    records = records.where('treatment_date <= ?', end_date) if end_date
    records.sum(:total_amount)
  end

  def medical_records_count
    medical_records.count
  end
end
```

**Step 3: マイグレーション作成**

```bash
rails generate model Facility user:references name:string address:text phone:string email:string notes:text
```

```ruby
# db/migrate/XXXXXX_create_facilities.rb
class CreateFacilities < ActiveRecord::Migration[7.1]
  def change
    create_table :facilities do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :address
      t.string :phone
      t.string :email
      t.text :notes

      t.timestamps
    end

    add_index :facilities, [:user_id, :name]
  end
end
```

```bash
rails db:migrate
```

**Step 4: テスト実行（確認）**

```bash
bundle exec rspec spec/models/facility_spec.rb
```

**Step 5: Factory 作成**

```ruby
# spec/factories/facilities.rb
FactoryBot.define do
  factory :facility do
    user
    name { "#{Faker::Company.name}クリニック" }
    address { Faker::Address.full_address }
    phone { '03-1234-5678' }
    email { Faker::Internet.email }
    notes { '毎週土曜日のみ施術' }

    trait :with_records do
      after(:create) do |facility|
        create_list(:medical_record, 3, facility: facility, user: facility.user)
      end
    end
  end
end
```

**Step 6: Request Spec を書く（Red）**

```ruby
# spec/requests/facilities_spec.rb
require 'rails_helper'

RSpec.describe 'Facilities', type: :request do
  let(:user) { create(:user) }
  let(:facility) { create(:facility, user: user) }

  before { sign_in user }

  describe 'GET /facilities' do
    it 'returns http success' do
      get facilities_path
      expect(response).to have_http_status(:success)
    end

    it 'displays all facilities' do
      facilities = create_list(:facility, 3, user: user)
      get facilities_path
      facilities.each do |facility|
        expect(response.body).to include(facility.name)
      end
    end
  end

  describe 'GET /facilities/:id' do
    it 'returns http success' do
      get facility_path(facility)
      expect(response).to have_http_status(:success)
    end

    it 'displays facility details' do
      get facility_path(facility)
      expect(response.body).to include(facility.name)
      expect(response.body).to include(facility.address)
    end
  end

  describe 'GET /facilities/new' do
    it 'returns http success' do
      get new_facility_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /facilities' do
    context 'with valid parameters' do
      let(:valid_params) do
        { facility: { name: 'テストクリニック', address: '東京都渋谷区' } }
      end

      it 'creates a new facility' do
        expect {
          post facilities_path, params: valid_params
        }.to change(Facility, :count).by(1)
      end

      it 'redirects to the facility page' do
        post facilities_path, params: valid_params
        expect(response).to redirect_to(Facility.last)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        { facility: { name: '' } }
      end

      it 'does not create a new facility' do
        expect {
          post facilities_path, params: invalid_params
        }.not_to change(Facility, :count)
      end

      it 'renders new template' do
        post facilities_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH /facilities/:id' do
    context 'with valid parameters' do
      let(:valid_params) do
        { facility: { name: '更新後クリニック' } }
      end

      it 'updates the facility' do
        patch facility_path(facility), params: valid_params
        facility.reload
        expect(facility.name).to eq('更新後クリニック')
      end

      it 'redirects to the facility page' do
        patch facility_path(facility), params: valid_params
        expect(response).to redirect_to(facility)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        { facility: { name: '' } }
      end

      it 'does not update the facility' do
        original_name = facility.name
        patch facility_path(facility), params: invalid_params
        facility.reload
        expect(facility.name).to eq(original_name)
      end
    end
  end

  describe 'DELETE /facilities/:id' do
    context 'when facility has no records' do
      it 'deletes the facility' do
        facility_to_delete = create(:facility, user: user)
        expect {
          delete facility_path(facility_to_delete)
        }.to change(Facility, :count).by(-1)
      end

      it 'redirects to facilities index' do
        delete facility_path(facility)
        expect(response).to redirect_to(facilities_path)
      end
    end

    context 'when facility has records' do
      let!(:facility_with_records) { create(:facility, :with_records, user: user) }

      it 'does not delete the facility' do
        expect {
          delete facility_path(facility_with_records)
        }.not_to change(Facility, :count)
      end

      it 'redirects back with alert' do
        delete facility_path(facility_with_records)
        expect(response).to redirect_to(facility_with_records)
        follow_redirect!
        expect(response.body).to include('施術記録が存在するため削除できません')
      end
    end
  end
end
```

**Step 7: Controller を実装（Green）**

```ruby
# app/controllers/facilities_controller.rb
class FacilitiesController < ApplicationController
  before_action :set_facility, only: [:show, :edit, :update, :destroy]

  def index
    @facilities = current_user.facilities.by_name.page(params[:page])
  end

  def show
    @medical_records = @facility.medical_records.recent.limit(10)
    @total_revenue = @facility.total_revenue
  end

  def new
    @facility = current_user.facilities.build
  end

  def create
    @facility = current_user.facilities.build(facility_params)

    if @facility.save
      redirect_to @facility, notice: '施術場所を登録しました'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @facility.update(facility_params)
      redirect_to @facility, notice: '施術場所を更新しました'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @facility.has_records?
      redirect_to @facility, alert: '施術記録が存在するため削除できません'
    else
      @facility.destroy
      redirect_to facilities_url, notice: '施術場所を削除しました'
    end
  end

  private

  def set_facility
    @facility = current_user.facilities.find(params[:id])
  end

  def facility_params
    params.require(:facility).permit(:name, :address, :phone, :email, :notes)
  end
end
```

**Step 8: ルーティング追加**

```ruby
# config/routes.rb
Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  root 'dashboard#index'

  get 'dashboard', to: 'dashboard#index'

  resources :facilities
  # 他のリソースは後で追加
end
```

**Step 9: Views を実装**

```erb
<%# app/views/facilities/index.html.erb %>
<div class="container mx-auto px-4 py-8">
  <div class="flex justify-between items-center mb-6">
    <h1 class="text-3xl font-bold text-gray-900">施術場所一覧</h1>
    <%= link_to '新規登録', new_facility_path,
                class: 'bg-blue-600 text-white px-6 py-2 rounded-md hover:bg-blue-700' %>
  </div>

  <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
    <% @facilities.each do |facility| %>
      <div class="bg-white rounded-lg shadow-md p-6">
        <h2 class="text-xl font-bold text-gray-900 mb-2"><%= facility.name %></h2>

        <% if facility.address.present? %>
          <p class="text-gray-600 text-sm mb-2">
            📍 <%= facility.address %>
          </p>
        <% end %>

        <% if facility.phone.present? %>
          <p class="text-gray-600 text-sm mb-2">
            📞 <%= facility.phone %>
          </p>
        <% end>

        <div class="mt-4 pt-4 border-t border-gray-200">
          <p class="text-sm text-gray-600">
            施術記録: <%= facility.medical_records_count %>件 |
            売上: ¥<%= facility.total_revenue.to_i.to_s(:delimited) %>
          </p>
        </div>

        <div class="mt-4 flex space-x-2">
          <%= link_to '詳細', facility_path(facility),
                      class: 'text-blue-600 hover:text-blue-800 text-sm' %>
          <%= link_to '編集', edit_facility_path(facility),
                      class: 'text-gray-600 hover:text-gray-800 text-sm' %>
          <%= link_to '削除', facility_path(facility),
                      data: { turbo_method: :delete, turbo_confirm: '本当に削除しますか?' },
                      class: 'text-red-600 hover:text-red-800 text-sm' %>
        </div>
      </div>
    <% end %>
  </div>

  <div class="mt-8">
    <%== pagy_nav(@pagy) if @pagy %>
  </div>
</div>
```

```erb
<%# app/views/facilities/show.html.erb %>
<div class="container mx-auto px-4 py-8">
  <%= link_to '← 一覧に戻る', facilities_path, class: 'text-blue-600 hover:text-blue-800 mb-4 inline-block' %>

  <div class="flex justify-between items-center mb-6">
    <h1 class="text-3xl font-bold text-gray-900"><%= @facility.name %></h1>
    <div class="space-x-2">
      <%= link_to '編集', edit_facility_path(@facility),
                  class: 'bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700' %>
      <%= link_to '削除', facility_path(@facility),
                  data: { turbo_method: :delete, turbo_confirm: '本当に削除しますか?' },
                  class: 'bg-red-600 text-white px-4 py-2 rounded-md hover:bg-red-700' %>
    </div>
  </div>

  <div class="bg-white rounded-lg shadow-md p-6 mb-6">
    <h2 class="text-xl font-bold mb-4">基本情報</h2>

    <dl class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <% if @facility.address.present? %>
        <div>
          <dt class="text-sm font-medium text-gray-500">住所</dt>
          <dd class="mt-1 text-sm text-gray-900">📍 <%= @facility.address %></dd>
        </div>
      <% end %>

      <% if @facility.phone.present? %>
        <div>
          <dt class="text-sm font-medium text-gray-500">電話番号</dt>
          <dd class="mt-1 text-sm text-gray-900">📞 <%= @facility.phone %></dd>
        </div>
      <% end %>

      <% if @facility.email.present? %>
        <div>
          <dt class="text-sm font-medium text-gray-500">メールアドレス</dt>
          <dd class="mt-1 text-sm text-gray-900">📧 <%= @facility.email %></dd>
        </div>
      <% end %>

      <% if @facility.notes.present? %>
        <div class="col-span-2">
          <dt class="text-sm font-medium text-gray-500">備考</dt>
          <dd class="mt-1 text-sm text-gray-900">📝 <%= @facility.notes %></dd>
        </div>
      <% end %>
    </dl>
  </div>

  <div class="bg-white rounded-lg shadow-md p-6 mb-6">
    <h2 class="text-xl font-bold mb-4">売上サマリー</h2>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <div>
        <p class="text-sm text-gray-500">総売上</p>
        <p class="text-2xl font-bold text-blue-600">¥<%= @total_revenue.to_i.to_s(:delimited) %></p>
      </div>
      <div>
        <p class="text-sm text-gray-500">施術記録数</p>
        <p class="text-2xl font-bold text-gray-700"><%= @facility.medical_records_count %>件</p>
      </div>
      <div>
        <p class="text-sm text-gray-500">平均単価</p>
        <p class="text-2xl font-bold text-gray-700">
          ¥<%= (@facility.medical_records_count > 0 ? @total_revenue / @facility.medical_records_count : 0).to_i.to_s(:delimited) %>
        </p>
      </div>
    </div>
  </div>

  <% if @medical_records.any? %>
    <div class="bg-white rounded-lg shadow-md p-6">
      <div class="flex justify-between items-center mb-4">
        <h2 class="text-xl font-bold">最近の施術記録</h2>
        <%= link_to 'すべての記録を見る', medical_records_path(q: { facility_id_eq: @facility.id }),
                    class: 'text-blue-600 hover:text-blue-800 text-sm' %>
      </div>

      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">施術日</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">患者名</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">施術内容</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">金額</th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <% @medical_records.each do |record| %>
              <tr>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  <%= l(record.treatment_date, format: :short) %>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  <%= link_to record.patient.name, patient_path(record.patient),
                              class: 'text-blue-600 hover:text-blue-800' %>
                </td>
                <td class="px-6 py-4 text-sm text-gray-900">
                  <%= truncate(record.treatment_content, length: 30) %>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                  ¥<%= record.total_amount.to_i.to_s(:delimited) %>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
  <% end %>
</div>
```

```erb
<%# app/views/facilities/_form.html.erb %>
<%= form_with(model: facility, local: true, class: 'space-y-6') do |f| %>
  <% if facility.errors.any? %>
    <div class="bg-red-50 border-l-4 border-red-500 p-4 mb-6">
      <h3 class="text-red-800 font-medium mb-2">
        <%= pluralize(facility.errors.count, "件のエラー") %>があります
      </h3>
      <ul class="list-disc list-inside text-red-700">
        <% facility.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div>
    <%= f.label :name, '施術場所名', class: 'block text-sm font-medium text-gray-700 mb-1' %>
    <%= f.text_field :name, class: 'border border-gray-300 rounded-md px-4 py-2 w-full focus:ring-2 focus:ring-blue-500 focus:border-transparent', placeholder: '○○クリニック' %>
  </div>

  <div>
    <%= f.label :address, '住所', class: 'block text-sm font-medium text-gray-700 mb-1' %>
    <%= f.text_area :address, rows: 2, class: 'border border-gray-300 rounded-md px-4 py-2 w-full focus:ring-2 focus:ring-blue-500 focus:border-transparent', placeholder: '東京都渋谷区...' %>
  </div>

  <div>
    <%= f.label :phone, '電話番号', class: 'block text-sm font-medium text-gray-700 mb-1' %>
    <%= f.telephone_field :phone, class: 'border border-gray-300 rounded-md px-4 py-2 w-full focus:ring-2 focus:ring-blue-500 focus:border-transparent', placeholder: '03-1234-5678' %>
  </div>

  <div>
    <%= f.label :email, 'メールアドレス', class: 'block text-sm font-medium text-gray-700 mb-1' %>
    <%= f.email_field :email, class: 'border border-gray-300 rounded-md px-4 py-2 w-full focus:ring-2 focus:ring-blue-500 focus:border-transparent', placeholder: 'contact@clinic.com' %>
  </div>

  <div>
    <%= f.label :notes, '備考', class: 'block text-sm font-medium text-gray-700 mb-1' %>
    <%= f.text_area :notes, rows: 3, class: 'border border-gray-300 rounded-md px-4 py-2 w-full focus:ring-2 focus:ring-blue-500 focus:border-transparent', placeholder: '営業時間、定休日など' %>
  </div>

  <div class="flex space-x-4">
    <%= link_to 'キャンセル', facilities_path, class: 'bg-gray-200 text-gray-700 px-6 py-2 rounded-md hover:bg-gray-300' %>
    <%= f.submit class: 'bg-blue-600 text-white px-6 py-2 rounded-md hover:bg-blue-700' %>
  </div>
<% end %>
```

```erb
<%# app/views/facilities/new.html.erb %>
<div class="container mx-auto px-4 py-8 max-w-2xl">
  <h1 class="text-3xl font-bold text-gray-900 mb-6">施術場所登録</h1>

  <div class="bg-white rounded-lg shadow-md p-6">
    <%= render 'form', facility: @facility %>
  </div>
</div>
```

```erb
<%# app/views/facilities/edit.html.erb %>
<div class="container mx-auto px-4 py-8 max-w-2xl">
  <h1 class="text-3xl font-bold text-gray-900 mb-6">施術場所編集</h1>

  <div class="bg-white rounded-lg shadow-md p-6">
    <%= render 'form', facility: @facility %>
  </div>
</div>
```

**Step 10: System Spec を書く（E2E テスト）**

```ruby
# spec/system/facilities_spec.rb
require 'rails_helper'

RSpec.describe 'Facilities', type: :system do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe '施術場所一覧' do
    it '施術場所の一覧が表示される' do
      facilities = create_list(:facility, 3, user: user)

      visit facilities_path

      expect(page).to have_content('施術場所一覧')
      facilities.each do |facility|
        expect(page).to have_content(facility.name)
      end
    end
  end

  describe '施術場所作成' do
    it '施術場所を新規作成できる' do
      visit new_facility_path

      fill_in '施術場所名', with: 'テストクリニック'
      fill_in '住所', with: '東京都渋谷区'
      fill_in '電話番号', with: '03-1234-5678'
      fill_in 'メールアドレス', with: 'test@clinic.com'

      click_button '登録する'

      expect(page).to have_content('施術場所を登録しました')
      expect(page).to have_content('テストクリニック')
    end

    it 'バリデーションエラーが表示される' do
      visit new_facility_path

      click_button '登録する'

      expect(page).to have_content('施術場所名を入力してください')
    end
  end

  describe '施術場所更新' do
    let(:facility) { create(:facility, user: user, name: '元の名前') }

    it '施術場所を更新できる' do
      visit edit_facility_path(facility)

      fill_in '施術場所名', with: '更新後の名前'
      click_button '更新する'

      expect(page).to have_content('施術場所を更新しました')
      expect(page).to have_content('更新後の名前')
    end
  end

  describe '施術場所削除' do
    context '施術記録がない場合' do
      let(:facility) { create(:facility, user: user) }

      it '施術場所を削除できる' do
        visit facility_path(facility)

        accept_confirm do
          click_link '削除'
        end

        expect(page).to have_content('施術場所を削除しました')
        expect(page).not_to have_content(facility.name)
      end
    end

    context '施術記録がある場合' do
      let(:facility) { create(:facility, :with_records, user: user) }

      it '削除できない' do
        visit facility_path(facility)

        accept_confirm do
          click_link '削除'
        end

        expect(page).to have_content('施術記録が存在するため削除できません')
      end
    end
  end
end
```

**Step 11: 全テスト実行**

```bash
# Model Spec
bundle exec rspec spec/models/facility_spec.rb

# Request Spec
bundle exec rspec spec/requests/facilities_spec.rb

# System Spec
bundle exec rspec spec/system/facilities_spec.rb

# または全体
bundle exec rspec
```

**Step 12: RuboCop 実行**

```bash
bundle exec rubocop -A
```

**Step 13: コミット**

```bash
git add .
git commit -m "Add Facility CRUD with full test coverage"
```

---

### 3.2 Day 3-4: Patient（患者）実装

Patient 実装は Facility とほぼ同様の流れです。

**差分ポイント:**

1. **enum 型（gender）の追加**
2. **検索機能（Ransack）**
3. **年齢計算メソッド**

**追加する Gem:**

```ruby
# Gemfile
gem 'ransack', '~> 4.0'
```

```bash
bundle install
```

**Model 実装:**

```ruby
# app/models/patient.rb
class Patient < ApplicationRecord
  belongs_to :user
  has_many :medical_records, dependent: :restrict_with_error
  has_many :facilities, through: :medical_records

  enum gender: { unspecified: 0, male: 1, female: 2, other: 3 }

  validates :name, presence: true, length: { maximum: 100 }
  validates :birth_date, comparison: { less_than_or_equal_to: -> { Date.today } }, allow_blank: true
  validates :phone, format: { with: /\A\d{2,4}-?\d{2,4}-?\d{3,4}\z/, allow_blank: true }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }

  scope :recent, -> { order(created_at: :desc) }
  scope :by_name, -> { order(:name) }
  scope :search_by_name, ->(query) { where('name LIKE ?', "%#{sanitize_sql_like(query)}%") }

  def age
    return nil unless birth_date

    today = Date.today
    age = today.year - birth_date.year
    age -= 1 if today < birth_date + age.years
    age
  end

  def has_records?
    medical_records.exists?
  end

  def last_treatment_date
    medical_records.maximum(:treatment_date)
  end

  def total_spent
    medical_records.sum(:total_amount)
  end
end
```

**Controller 実装（検索機能付き）:**

```ruby
# app/controllers/patients_controller.rb
class PatientsController < ApplicationController
  before_action :set_patient, only: [:show, :edit, :update, :destroy]

  def index
    @q = current_user.patients.ransack(params[:q])
    @patients = @q.result.by_name.page(params[:page])
  end

  def show
    @medical_records = @patient.medical_records.recent.includes(:facility).limit(10)
  end

  def new
    @patient = current_user.patients.build
  end

  def create
    @patient = current_user.patients.build(patient_params)

    if @patient.save
      redirect_to @patient, notice: '患者を登録しました'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @patient.update(patient_params)
      redirect_to @patient, notice: '患者情報を更新しました'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @patient.has_records?
      redirect_to @patient, alert: '施術記録が存在するため削除できません'
    else
      @patient.destroy
      redirect_to patients_url, notice: '患者を削除しました'
    end
  end

  private

  def set_patient
    @patient = current_user.patients.find(params[:id])
  end

  def patient_params
    params.require(:patient).permit(
      :name, :birth_date, :gender, :phone, :email,
      :allergy_info, :medical_history, :notes
    )
  end
end
```

**検索フォーム（Ransack）:**

```erb
<%# app/views/patients/index.html.erb %>
<div class="container mx-auto px-4 py-8">
  <div class="flex justify-between items-center mb-6">
    <h1 class="text-3xl font-bold text-gray-900">患者一覧</h1>
    <%= link_to '新規登録', new_patient_path,
                class: 'bg-blue-600 text-white px-6 py-2 rounded-md hover:bg-blue-700' %>
  </div>

  <!-- 検索フォーム -->
  <div class="bg-white rounded-lg shadow-md p-4 mb-6">
    <%= search_form_for @q, url: patients_path, html: { class: 'flex space-x-4' } do |f| %>
      <%= f.search_field :name_cont, placeholder: '患者名で検索',
                         class: 'flex-1 border border-gray-300 rounded-md px-4 py-2' %>
      <%= f.submit '検索', class: 'bg-blue-600 text-white px-6 py-2 rounded-md hover:bg-blue-700' %>
      <%= link_to 'リセット', patients_path, class: 'bg-gray-200 text-gray-700 px-6 py-2 rounded-md hover:bg-gray-300' %>
    <% end %>
  </div>

  <!-- 患者一覧 -->
  <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
    <% @patients.each do |patient| %>
      <div class="bg-white rounded-lg shadow-md p-6">
        <h2 class="text-xl font-bold text-gray-900 mb-2">
          <%= patient.name %>
          <% if patient.age.present? %>
            <span class="text-gray-600 text-base">（<%= patient.age %>歳）</span>
          <% end %>
        </h2>

        <% if patient.phone.present? %>
          <p class="text-gray-600 text-sm mb-2">📞 <%= patient.phone %></p>
        <% end %>

        <% if patient.last_treatment_date.present? %>
          <p class="text-gray-600 text-sm mb-2">
            最終施術日: <%= l(patient.last_treatment_date, format: :short) %>
          </p>
        <% end %>

        <div class="mt-4 pt-4 border-t border-gray-200">
          <p class="text-sm text-gray-600">
            施術回数: <%= patient.medical_records.count %>回 |
            累計: ¥<%= patient.total_spent.to_i.to_s(:delimited) %>
          </p>
        </div>

        <div class="mt-4 flex space-x-2">
          <%= link_to '詳細', patient_path(patient),
                      class: 'text-blue-600 hover:text-blue-800 text-sm' %>
          <%= link_to '編集', edit_patient_path(patient),
                      class: 'text-gray-600 hover:text-gray-800 text-sm' %>
          <%= link_to '削除', patient_path(patient),
                      data: { turbo_method: :delete, turbo_confirm: '本当に削除しますか?' },
                      class: 'text-red-600 hover:text-red-800 text-sm' %>
        </div>
      </div>
    <% end %>
  </div>

  <div class="mt-8">
    <%== pagy_nav(@pagy) if @pagy %>
  </div>
</div>
```

---

### 3.3 Day 5-6: CostSheet（コストシート）実装

CostSheet は比較的シンプルな CRUD です。

**特徴:**

- カテゴリ選択（treatment/medicine/supplies/other）
- 標準価格の設定

実装手順は Facility と同様。

---

## 4. Week 5-6: カルテ機能実装（最重要）

### 4.1 Day 1-2: MedicalRecord + CostItem モデル実装

#### 4.1.1 マイグレーション

```bash
rails generate model MedicalRecord user:references patient:references facility:references invoice:references treatment_date:date treatment_content:text counseling_content:text total_amount:decimal

rails generate model CostItem medical_record:references cost_sheet:references item_name:string unit_price:decimal quantity:integer subtotal:decimal notes:text

rails generate model Tag user:references name:string category:string color:string

rails generate model MedicalRecordTag medical_record:references tag:references
```

**マイグレーション調整:**

```ruby
# db/migrate/XXXXXX_create_medical_records.rb
class CreateMedicalRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :medical_records do |t|
      t.references :user, null: false, foreign_key: true
      t.references :patient, null: false, foreign_key: true
      t.references :facility, null: false, foreign_key: true
      t.references :invoice, foreign_key: true
      t.date :treatment_date, null: false
      t.text :treatment_content
      t.text :counseling_content
      t.decimal :total_amount, precision: 10, scale: 2, default: 0, null: false

      t.timestamps
    end

    add_index :medical_records, [:user_id, :treatment_date]
    add_index :medical_records, [:facility_id, :treatment_date]
    add_index :medical_records, [:patient_id, :treatment_date]
  end
end
```

```ruby
# db/migrate/XXXXXX_create_cost_items.rb
class CreateCostItems < ActiveRecord::Migration[7.1]
  def change
    create_table :cost_items do |t|
      t.references :medical_record, null: false, foreign_key: true
      t.references :cost_sheet, foreign_key: true
      t.string :item_name, null: false
      t.decimal :unit_price, precision: 10, scale: 2, default: 0, null: false
      t.integer :quantity, default: 1, null: false
      t.decimal :subtotal, precision: 10, scale: 2, default: 0, null: false
      t.text :notes

      t.timestamps
    end
  end
end
```

```bash
rails db:migrate
```

#### 4.1.2 Active Storage セットアップ

```bash
rails active_storage:install
rails db:migrate
```

**storage.yml 確認:**

```yaml
# config/storage.yml
local:
  service: Disk
  root: <%= Rails.root.join("storage") %>

cloudflare:
  service: S3
  access_key_id: <%= ENV['R2_ACCESS_KEY_ID'] %>
  secret_access_key: <%= ENV['R2_SECRET_ACCESS_KEY'] %>
  endpoint: <%= ENV['R2_ENDPOINT'] %>
  region: auto
  bucket: <%= ENV['R2_BUCKET_NAME'] %>
  force_path_style: true
```

**環境設定:**

```ruby
# config/environments/development.rb
config.active_storage.service = :local

# config/environments/production.rb
config.active_storage.service = :cloudflare
```

#### 4.1.3 Model 実装

```ruby
# app/models/medical_record.rb
class MedicalRecord < ApplicationRecord
  belongs_to :user
  belongs_to :patient
  belongs_to :facility
  belongs_to :invoice, optional: true

  has_many :cost_items, dependent: :destroy
  has_many :medical_record_tags, dependent: :destroy
  has_many :tags, through: :medical_record_tags

  has_many_attached :photos

  accepts_nested_attributes_for :cost_items, allow_destroy: true, reject_if: :all_blank

  validates :treatment_date, presence: true
  validates :treatment_date, comparison: { less_than_or_equal_to: -> { Date.today } }
  validates :total_amount, numericality: { greater_than_or_equal_to: 0 }
  validate :photos_count_limit
  validate :photos_size_limit

  after_save :update_total_amount
  before_destroy :check_invoice_association

  scope :recent, -> { order(treatment_date: :desc, created_at: :desc) }
  scope :by_date, -> { order(:treatment_date) }
  scope :in_period, ->(start_date, end_date) { where(treatment_date: start_date..end_date) }
  scope :by_facility, ->(facility_id) { where(facility_id: facility_id) }
  scope :by_patient, ->(patient_id) { where(patient_id: patient_id) }
  scope :unbilled, -> { where(invoice_id: nil) }
  scope :billed, -> { where.not(invoice_id: nil) }

  def can_destroy?
    invoice_id.nil?
  end

  def add_tag(tag_name)
    tag = user.tags.find_or_create_by(name: tag_name)
    tags << tag unless tags.include?(tag)
    tag
  end

  def remove_tag(tag)
    tags.delete(tag)
  end

  def thumbnail
    photos.first&.variant(resize_to_limit: [200, 200])
  end

  private

  def update_total_amount
    new_total = cost_items.sum(:subtotal)
    update_column(:total_amount, new_total) if total_amount != new_total
  end

  def check_invoice_association
    if invoice_id.present?
      errors.add(:base, '請求書に含まれているカルテは削除できません')
      throw(:abort)
    end
  end

  def photos_count_limit
    if photos.count > 5
      errors.add(:photos, '写真は最大5枚までアップロードできます')
    end
  end

  def photos_size_limit
    photos.each do |photo|
      if photo.byte_size > 10.megabytes
        errors.add(:photos, "#{photo.filename}のサイズが10MBを超えています")
      end
    end
  end
end
```

```ruby
# app/models/cost_item.rb
class CostItem < ApplicationRecord
  belongs_to :medical_record
  belongs_to :cost_sheet, optional: true

  validates :item_name, presence: true
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :subtotal, numericality: { greater_than_or_equal_to: 0 }

  before_save :calculate_subtotal
  after_save :update_medical_record_total
  after_destroy :update_medical_record_total

  private

  def calculate_subtotal
    self.subtotal = unit_price * quantity
  end

  def update_medical_record_total
    medical_record.update_total_amount
  end
end
```

---

### 4.2 Day 3-4: 動的フォーム（Stimulus）実装

#### 4.2.1 Stimulus セットアップ確認

```bash
# Hotwire（Turbo + Stimulus）が既にセットアップされているか確認
cat app/javascript/application.js
```

```javascript
// app/javascript/application.js
import '@hotwired/turbo-rails';
import './controllers';
```

#### 4.2.2 cost_items_controller.js 実装

```javascript
// app/javascript/controllers/cost_items_controller.js
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['container', 'template', 'total', 'addButton'];
  static values = {
    costSheets: Array,
    maxItems: { type: Number, default: 10 },
  };

  connect() {
    this.updateTotal();
    this.updateAddButtonState();
  }

  addItem(event) {
    event.preventDefault();

    if (this.itemCount >= this.maxItemsValue) {
      alert(`コスト項目は最大${this.maxItemsValue}件までです`);
      return;
    }

    const content = this.templateTarget.innerHTML.replace(
      /NEW_RECORD/g,
      new Date().getTime()
    );
    this.containerTarget.insertAdjacentHTML('beforeend', content);
    this.updateAddButtonState();
  }

  removeItem(event) {
    event.preventDefault();
    const item = event.target.closest('.cost-item');

    if (this.itemCount <= 1) {
      alert('最低1つのコスト項目が必要です');
      return;
    }

    const destroyInput = item.querySelector('input[name*="_destroy"]');
    if (destroyInput) {
      destroyInput.value = '1';
      item.style.display = 'none';
    } else {
      item.remove();
    }

    this.calculateTotal();
    this.updateAddButtonState();
  }

  selectCostSheet(event) {
    const select = event.target;
    const costSheetId = select.value;

    if (!costSheetId) return;

    const costSheet = this.costSheetsValue.find((cs) => cs.id == costSheetId);
    if (!costSheet) return;

    const item = select.closest('.cost-item');
    const nameInput = item.querySelector('.item-name');
    const priceInput = item.querySelector('.unit-price');

    if (nameInput) nameInput.value = costSheet.item_name;
    if (priceInput) priceInput.value = costSheet.standard_price;

    this.calculateTotal();
  }

  calculateTotal() {
    let total = 0;

    this.containerTarget
      .querySelectorAll('.cost-item:not([style*="display: none"])')
      .forEach((item) => {
        const price = parseFloat(item.querySelector('.unit-price').value) || 0;
        const qty = parseInt(item.querySelector('.quantity').value) || 1;
        const subtotal = price * qty;

        const subtotalDisplay = item.querySelector('.subtotal-display');
        if (subtotalDisplay) {
          subtotalDisplay.textContent = `¥${subtotal.toLocaleString()}`;
        }

        total += subtotal;
      });

    this.totalTarget.textContent = `¥${total.toLocaleString()}`;
  }

  updateTotal(event) {
    this.calculateTotal();
  }

  get itemCount() {
    return this.containerTarget.querySelectorAll(
      '.cost-item:not([style*="display: none"])'
    ).length;
  }

  updateAddButtonState() {
    if (this.hasAddButtonTarget) {
      this.addButtonTarget.disabled = this.itemCount >= this.maxItemsValue;
    }
  }
}
```

#### 4.2.3 image_preview_controller.js 実装

```javascript
// app/javascript/controllers/image_preview_controller.js
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['input', 'preview', 'container'];
  static values = {
    maxFiles: { type: Number, default: 5 },
    maxSize: { type: Number, default: 10485760 }, // 10MB
  };

  preview(event) {
    const files = Array.from(event.target.files);

    // ファイル数チェック
    const currentFiles = this.previewTargets.length;
    if (currentFiles + files.length > this.maxFilesValue) {
      alert(`画像は最大${this.maxFilesValue}枚までアップロードできます`);
      this.inputTarget.value = '';
      return;
    }

    // ファイルサイズチェック
    for (const file of files) {
      if (file.size > this.maxSizeValue) {
        alert(`${file.name}のサイズが10MBを超えています`);
        this.inputTarget.value = '';
        return;
      }
    }

    // プレビュー表示
    files.forEach((file) => {
      const reader = new FileReader();
      reader.onload = (e) => {
        const html = `
          <div class="image-preview-item relative" data-image-preview-target="preview">
            <img src="${e.target.result}" alt="プレビュー" class="w-full h-48 object-cover rounded-md" />
            <button type="button" class="absolute top-2 right-2 bg-red-600 text-white rounded-full w-8 h-8 flex items-center justify-center hover:bg-red-700" data-action="click->image-preview#remove">
              ×
            </button>
          </div>
        `;
        this.containerTarget.insertAdjacentHTML('beforeend', html);
      };
      reader.readAsDataURL(file);
    });
  }

  remove(event) {
    event.preventDefault();
    const previewItem = event.target.closest('.image-preview-item');
    previewItem.remove();

    // ファイル入力をリセット（再選択可能にする）
    this.inputTarget.value = '';
  }
}
```

---

### 4.3 Day 5-6: MedicalRecordsController + Views 実装

#### 4.3.1 Controller 実装

```ruby
# app/controllers/medical_records_controller.rb
class MedicalRecordsController < ApplicationController
  before_action :set_medical_record, only: [:show, :edit, :update, :destroy]
  before_action :load_form_data, only: [:new, :edit, :create, :update]

  def index
    @q = current_user.medical_records.ransack(params[:q])
    @medical_records = @q.result
                         .includes(:patient, :facility, :tags)
                         .recent
                         .page(params[:page])
  end

  def show
  end

  def new
    @medical_record = current_user.medical_records.build
    @medical_record.cost_items.build
  end

  def create
    @medical_record = current_user.medical_records.build(medical_record_params)

    if @medical_record.save
      process_tags if params[:medical_record][:tag_names].present?
      redirect_to @medical_record, notice: 'カルテを作成しました'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @medical_record.update(medical_record_params)
      process_tags if params[:medical_record][:tag_names].present?
      redirect_to @medical_record, notice: 'カルテを更新しました'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @medical_record.can_destroy?
      @medical_record.destroy
      redirect_to medical_records_url, notice: 'カルテを削除しました'
    else
      redirect_to @medical_record, alert: '請求書に含まれているため削除できません'
    end
  end

  private

  def set_medical_record
    @medical_record = current_user.medical_records.find(params[:id])
  end

  def load_form_data
    @patients = current_user.patients.by_name
    @facilities = current_user.facilities.by_name
    @cost_sheets = current_user.cost_sheets.by_name
    @cost_sheets_json = @cost_sheets.map { |cs| { id: cs.id, item_name: cs.item_name, standard_price: cs.standard_price } }.to_json
  end

  def medical_record_params
    params.require(:medical_record).permit(
      :patient_id, :facility_id, :treatment_date,
      :treatment_content, :counseling_content,
      photos: [],
      cost_items_attributes: [
        :id, :cost_sheet_id, :item_name, :unit_price, :quantity, :notes, :_destroy
      ]
    )
  end

  def process_tags
    tag_names = params[:medical_record][:tag_names].split(',').map(&:strip)
    @medical_record.tags.clear
    tag_names.each do |name|
      @medical_record.add_tag(name) if name.present?
    end
  end
end
```

#### 4.3.2 フォーム View 実装

```erb
<%# app/views/medical_records/_form.html.erb %>
<%= form_with(model: medical_record, local: true,
              data: {
                controller: 'cost-items image-preview',
                cost_items_cost_sheets_value: @cost_sheets_json,
                cost_items_max_items_value: 10
              },
              class: 'space-y-8') do |f| %>

  <% if medical_record.errors.any? %>
    <div class="bg-red-50 border-l-4 border-red-500 p-4">
      <h3 class="text-red-800 font-medium mb-2">
        <%= pluralize(medical_record.errors.count, "件のエラー") %>があります
      </h3>
      <ul class="list-disc list-inside text-red-700">
        <% medical_record.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <!-- 基本情報 -->
  <div class="bg-white rounded-lg shadow-md p-6">
    <h2 class="text-xl font-bold mb-4">基本情報</h2>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <div>
        <%= f.label :treatment_date, '施術日', class: 'block text-sm font-medium text-gray-700 mb-1' %>
        <%= f.date_field :treatment_date, value: medical_record.treatment_date || Date.today,
                         class: 'border border-gray-300 rounded-md px-4 py-2 w-full' %>
      </div>

      <div>
        <%= f.label :patient_id, '患者', class: 'block text-sm font-medium text-gray-700 mb-1' %>
        <%= f.collection_select :patient_id, @patients, :id, :name,
                                { prompt: '患者を選択' },
                                { class: 'border border-gray-300 rounded-md px-4 py-2 w-full' } %>
      </div>

      <div>
        <%= f.label :facility_id, '施術場所', class: 'block text-sm font-medium text-gray-700 mb-1' %>
        <%= f.collection_select :facility_id, @facilities, :id, :name,
                                { prompt: '施術場所を選択' },
                                { class: 'border border-gray-300 rounded-md px-4 py-2 w-full' } %>
      </div>
    </div>
  </div>

  <!-- 施術内容・カウンセリング -->
  <div class="bg-white rounded-lg shadow-md p-6">
    <h2 class="text-xl font-bold mb-4">施術内容</h2>

    <div class="space-y-4">
      <div>
        <%= f.label :treatment_content, '施術内容', class: 'block text-sm font-medium text-gray-700 mb-1' %>
        <%= f.text_area :treatment_content, rows: 4,
                        class: 'border border-gray-300 rounded-md px-4 py-2 w-full' %>
      </div>

      <div>
        <%= f.label :counseling_content, 'カウンセリング内容', class: 'block text-sm font-medium text-gray-700 mb-1' %>
        <%= f.text_area :counseling_content, rows: 4,
                        class: 'border border-gray-300 rounded-md px-4 py-2 w-full' %>
      </div>
    </div>
  </div>

  <!-- コスト項目（動的フォーム） -->
  <div class="bg-white rounded-lg shadow-md p-6">
    <div class="flex justify-between items-center mb-4">
      <h2 class="text-xl font-bold">コスト項目</h2>
      <p class="text-lg font-bold" data-cost-items-target="total">¥0</p>
    </div>

    <div data-cost-items-target="container" class="space-y-4">
      <%= f.fields_for :cost_items do |ci| %>
        <div class="cost-item border rounded-lg p-4 bg-gray-50">
          <div class="grid grid-cols-1 md:grid-cols-12 gap-4">
            <div class="md:col-span-3">
              <%= ci.label :cost_sheet_id, 'コストシート', class: 'block text-sm font-medium text-gray-700 mb-1' %>
              <%= ci.collection_select :cost_sheet_id, @cost_sheets, :id, :item_name,
                                      { include_blank: 'コストシートから選択' },
                                      { class: 'border border-gray-300 rounded-md px-3 py-2 w-full text-sm',
                                        data: { action: 'change->cost-items#selectCostSheet' } } %>
            </div>

            <div class="md:col-span-3">
              <%= ci.label :item_name, '項目名', class: 'block text-sm font-medium text-gray-700 mb-1' %>
              <%= ci.text_field :item_name, placeholder: '眉毛アートメイク',
                                class: 'item-name border border-gray-300 rounded-md px-3 py-2 w-full text-sm' %>
            </div>

            <div class="md:col-span-2">
              <%= ci.label :unit_price, '単価', class: 'block text-sm font-medium text-gray-700 mb-1' %>
              <%= ci.number_field :unit_price, placeholder: '50000',
                                  class: 'unit-price border border-gray-300 rounded-md px-3 py-2 w-full text-sm',
                                  data: { action: 'input->cost-items#updateTotal' } %>
            </div>

            <div class="md:col-span-2">
              <%= ci.label :quantity, '数量', class: 'block text-sm font-medium text-gray-700 mb-1' %>
              <%= ci.number_field :quantity, value: ci.object.quantity || 1,
                                  class: 'quantity border border-gray-300 rounded-md px-3 py-2 w-full text-sm',
                                  data: { action: 'input->cost-items#updateTotal' } %>
            </div>

            <div class="md:col-span-2 flex flex-col justify-end">
              <p class="subtotal-display text-lg font-bold text-gray-900 mb-2">¥0</p>
              <button type="button"
                      data-action="click->cost-items#removeItem"
                      class="bg-red-600 text-white px-3 py-1 rounded-md hover:bg-red-700 text-sm">
                削除
              </button>
              <%= ci.hidden_field :_destroy %>
            </div>
          </div>

          <div class="mt-2">
            <%= ci.label :notes, '備考', class: 'block text-sm font-medium text-gray-700 mb-1' %>
            <%= ci.text_field :notes, placeholder: '備考',
                              class: 'border border-gray-300 rounded-md px-3 py-2 w-full text-sm' %>
          </div>
        </div>
      <% end %>
    </div>

    <!-- テンプレート（非表示） -->
    <template data-cost-items-target="template">
      <%= f.fields_for :cost_items, CostItem.new, child_index: 'NEW_RECORD' do |ci| %>
        <div class="cost-item border rounded-lg p-4 bg-gray-50">
          <div class="grid grid-cols-1 md:grid-cols-12 gap-4">
            <div class="md:col-span-3">
              <%= ci.label :cost_sheet_id, 'コストシート', class: 'block text-sm font-medium text-gray-700 mb-1' %>
              <%= ci.collection_select :cost_sheet_id, @cost_sheets, :id, :item_name,
                                      { include_blank: 'コストシートから選択' },
                                      { class: 'border border-gray-300 rounded-md px-3 py-2 w-full text-sm',
                                        data: { action: 'change->cost-items#selectCostSheet' } } %>
            </div>

            <div class="md:col-span-3">
              <%= ci.label :item_name, '項目名', class: 'block text-sm font-medium text-gray-700 mb-1' %>
              <%= ci.text_field :item_name, placeholder: '眉毛アートメイク',
                                class: 'item-name border border-gray-300 rounded-md px-3 py-2 w-full text-sm' %>
            </div>

            <div class="md:col-span-2">
              <%= ci.label :unit_price, '単価', class: 'block text-sm font-medium text-gray-700 mb-1' %>
              <%= ci.number_field :unit_price, placeholder: '50000',
                                  class: 'unit-price border border-gray-300 rounded-md px-3 py-2 w-full text-sm',
                                  data: { action: 'input->cost-items#updateTotal' } %>
            </div>

            <div class="md:col-span-2">
              <%= ci.label :quantity, '数量', class: 'block text-sm font-medium text-gray-700 mb-1' %>
              <%= ci.number_field :quantity, value: 1,
                                  class: 'quantity border border-gray-300 rounded-md px-3 py-2 w-full text-sm',
                                  data: { action: 'input->cost-items#updateTotal' } %>
            </div>

            <div class="md:col-span-2 flex flex-col justify-end">
              <p class="subtotal-display text-lg font-bold text-gray-900 mb-2">¥0</p>
              <button type="button"
                      data-action="click->cost-items#removeItem"
                      class="bg-red-600 text-white px-3 py-1 rounded-md hover:bg-red-700 text-sm">
                削除
              </button>
              <%= ci.hidden_field :_destroy %>
            </div>
          </div>

          <div class="mt-2">
            <%= ci.label :notes, '備考', class: 'block text-sm font-medium text-gray-700 mb-1' %>
            <%= ci.text_field :notes, placeholder: '備考',
                              class: 'border border-gray-300 rounded-md px-3 py-2 w-full text-sm' %>
          </div>
        </div>
      <% end %>
    </template>

    <div class="mt-4">
      <button type="button"
              data-action="click->cost-items#addItem"
              data-cost-items-target="addButton"
              class="bg-green-600 text-white px-4 py-2 rounded-md hover:bg-green-700">
        + コスト項目を追加
      </button>
    </div>
  </div>

  <!-- 写真アップロード -->
  <div class="bg-white rounded-lg shadow-md p-6">
    <h2 class="text-xl font-bold mb-4">写真アップロード</h2>
    <p class="text-sm text-gray-600 mb-4">最大5枚、各10MBまで</p>

    <%= f.file_field :photos, multiple: true, accept: 'image/*',
                     data: {
                       action: 'change->image-preview#preview',
                       image_preview_target: 'input'
                     },
                     class: 'block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100' %>

    <div data-image-preview-target="container" class="grid grid-cols-2 md:grid-cols-3 gap-4 mt-4">
      <!-- プレビュー画像がここに追加される -->
    </div>
  </div>

  <!-- タグ -->
  <div class="bg-white rounded-lg shadow-md p-6">
    <h2 class="text-xl font-bold mb-4">タグ</h2>
    <%= text_field_tag 'medical_record[tag_names]',
                       medical_record.tags.map(&:name).join(', '),
                       placeholder: '初回施術, フォローアップ, リタッチ',
                       class: 'border border-gray-300 rounded-md px-4 py-2 w-full' %>
    <p class="text-sm text-gray-600 mt-2">カンマ区切りで入力してください</p>
  </div>

  <!-- 送信ボタン -->
  <div class="flex space-x-4">
    <%= link_to 'キャンセル', medical_records_path, class: 'bg-gray-200 text-gray-700 px-6 py-3 rounded-md hover:bg-gray-300' %>
    <%= f.submit class: 'bg-blue-600 text-white px-6 py-3 rounded-md hover:bg-blue-700' %>
  </div>
<% end %>
```

---

## 5. テスト実行とデバッグ

### 5.1 全テスト実行

```bash
# Model Spec
bundle exec rspec spec/models

# Request Spec
bundle exec rspec spec/requests

# System Spec
bundle exec rspec spec/system

# カバレッジ付き全テスト
COVERAGE=true bundle exec rspec
```

### 5.2 カバレッジ確認

```bash
open coverage/index.html
```

**目標: 80%以上**

### 5.3 RuboCop 実行

```bash
# 自動修正
bundle exec rubocop -A

# 修正なし確認のみ
bundle exec rubocop
```

### 5.4 SystemSpec デバッグ

**失敗時のスクリーンショット確認:**

```bash
ls tmp/screenshots
```

**ブラウザを開いて確認:**

```ruby
# spec/rails_helper.rb
# driven_by :selenium_chrome_headless を以下に変更
driven_by :selenium_chrome  # ヘッドレスモードを無効化
```

---

## 6. Phase 1 完了チェックリスト

### 6.1 機能実装

- [ ] Facility CRUD（施術場所管理）
- [ ] Patient CRUD + 検索（患者管理）
- [ ] CostSheet CRUD（コストシート管理）
- [ ] MedicalRecord CRUD（カルテ管理）
- [ ] CostItem nested attributes（コスト項目動的フォーム）
- [ ] 画像アップロード（Active Storage + Cloudflare R2）
- [ ] タグ機能
- [ ] 検索・フィルタリング（Ransack）

### 6.2 テスト

- [ ] Model Spec（全モデル）
- [ ] Request Spec（全コントローラー）
- [ ] System Spec（主要ユーザーフロー）
- [ ] カバレッジ 80%以上

### 6.3 コード品質

- [ ] RuboCop 違反 0 件
- [ ] N+1 クエリ検出なし（Bullet gem）
- [ ] 日本語ロケールファイル完成

### 6.4 ドキュメント

- [ ] README 更新（Phase 1 完了）
- [ ] CHANGELOG 作成

---

## 7. Phase 1 完了後のアクション

### 7.1 Git 操作

```bash
# Phase 1完了コミット
git add .
git commit -m "Complete Phase 1: MVP implementation

- Facility CRUD
- Patient CRUD with search
- CostSheet CRUD
- MedicalRecord CRUD with dynamic form
- Image upload with Active Storage
- Tag system
- Test coverage: 85%"

# mainにマージ
git checkout main
git merge feature/phase1-setup

# Phase 2ブランチ作成
git checkout -b feature/phase2-invoices
```

### 7.2 本番デプロイ準備（Phase 4 まで待つ）

Phase 1 完了時点では**デプロイしない**。Phase 2（請求書機能）完了後にデプロイを検討。

---

## 8. トラブルシューティング

### 8.1 Stimulus が動作しない

**問題:** 動的フォームが動作しない

**確認:**

```bash
# application.jsの確認
cat app/javascript/application.js

# Stimulusコントローラーの確認
ls app/javascript/controllers
```

**解決策:**

```bash
# Stimulusコントローラーを再度登録
rails stimulus:install
```

### 8.2 Active Storage 画像が表示されない

**問題:** アップロードした画像が表示されない

**確認:**

```ruby
# Rails console
rails console
> ActiveStorage::Blob.last
> ActiveStorage::Blob.last.service_url
```

**解決策:**

```ruby
# config/storage.ymlの確認
# 環境変数の確認
ENV['R2_ACCESS_KEY_ID']
ENV['R2_SECRET_ACCESS_KEY']
ENV['R2_ENDPOINT']
ENV['R2_BUCKET_NAME']
```

### 8.3 N+1 クエリ警告

**問題:** Bullet が N+1 を検出

**解決策:**

```ruby
# includesを追加
@medical_records = @q.result
                     .includes(:patient, :facility, :tags)  # ← これを追加
                     .recent
                     .page(params[:page])
```

### 8.4 Ransack 検索が動作しない

**問題:** 検索フォームが反応しない

**確認:**

```ruby
# Gemfile
gem 'ransack', '~> 4.0'
```

```bash
bundle install
```

**解決策:**

```ruby
# Controllerで正しく設定
@q = current_user.patients.ransack(params[:q])
@patients = @q.result.by_name.page(params[:page])
```

---

**Document Version**: 1.0
**Last Updated**: 2025-10-12
**Next Review**: Phase 1 完了時

---

## 付録: 便利なコマンド集

### 開発用

```bash
# サーバー起動
rails s

# Console起動
rails console

# ルーティング確認
rails routes | grep medical_records

# データベースリセット
rails db:reset

# シードデータ投入
rails db:seed
```

### テスト用

```bash
# 特定のSpecファイル実行
bundle exec rspec spec/models/medical_record_spec.rb

# 特定のテスト実行（行番号指定）
bundle exec rspec spec/models/medical_record_spec.rb:25

# 失敗したテストのみ再実行
bundle exec rspec --only-failures

# 詳細出力
bundle exec rspec --format documentation
```

### デバッグ用

```bash
# ログ確認
tail -f log/development.log

# テストログ確認
tail -f log/test.log

# SystemSpecスクリーンショット
open tmp/screenshots/screenshot-*.png
```

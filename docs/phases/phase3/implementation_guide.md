# Phase 3: カルテ管理機能実装ガイド

**作成日**: 2025-10-13  
**対象**: Phase 3（カルテ管理、コストシート、画像アップロード、検索機能）  
**期間**: Week 1-5（約5週間）  
**前提**: Phase 2完了（患者管理 + 問診票機能が動作）

---

## 目次

1. [概要](#1-概要)
2. [前提条件](#2-前提条件)
3. [実装の流れ](#3-実装の流れ)
4. [Week 1-2: 基盤整備](#4-week-1-2-基盤整備)
5. [Week 3: コスト統合](#5-week-3-コスト統合)
6. [Week 4: フロントエンド強化](#6-week-4-フロントエンド強化)
7. [Week 5: 完成](#7-week-5-完成)
8. [トラブルシューティング](#8-トラブルシューティング)
9. [成功基準](#9-成功基準)

---

## 1. 概要

### 1.1 Phase 3の目的

Phase 3では、アプリの中心機能である**カルテ管理システム**を実装します。

**主要機能:**
- コストシート管理（施術料金テンプレート）
- カルテ管理（施術記録）
- コスト項目の動的追加（nested attributes + Stimulus）
- 画像アップロード（Active Storage）
- タグ機能（分類・フィルタリング）
- 高度な検索機能（Ransack）

### 1.2 実装範囲

| 機能 | 説明 | 複雑度 |
|------|------|--------|
| CostSheet | 料金テンプレート管理 | ⭐️ 低 |
| MedicalRecord | カルテCRUD | ⭐️⭐️ 中 |
| CostItem | nested attributes | ⭐️⭐️⭐️ 高 |
| Active Storage | 画像アップロード | ⭐️⭐️ 中 |
| Stimulus | 動的フォーム | ⭐️⭐️⭐️ 高 |
| Tag | タグ機能 | ⭐️⭐️ 中 |
| Search | 検索強化 | ⭐️⭐️ 中 |

### 1.3 データモデル関係図

```
User（施術者）
  ├─ Facility（施術場所）← Phase 1
  ├─ Patient（患者）← Phase 2
  ├─ CostSheet（コストシート）← Phase 3
  └─ MedicalRecord（カルテ）← Phase 3
      ├─ CostItem（コスト項目）← Phase 3
      ├─ Tag（タグ）← Phase 3
      └─ Photos（画像）← Phase 3 (Active Storage)
```

---

## 2. 前提条件

### 2.1 Phase 2完了確認

```bash
# Phase 2のテストが全て成功していることを確認
bundle exec rspec spec/models/patient_spec.rb
bundle exec rspec spec/models/questionnaire_spec.rb
bundle exec rspec spec/requests/patients_spec.rb
bundle exec rspec spec/requests/questionnaires_spec.rb

# 全て成功すればOK ✅
```

### 2.2 必要なGemの追加

```ruby
# Gemfile に以下を追加

# 画像処理（Active Storage用）
gem 'image_processing', '~> 1.12'

# 検索機能強化
gem 'ransack', '~> 4.0'

# ページネーション（既存）
gem 'kaminari', '~> 1.2'
```

```bash
bundle install
```

### 2.3 ブランチ作成

```bash
git checkout main
git pull origin main
git checkout -b feature/phase3-cost-sheet
```

---

## 3. 実装の流れ

### 3.1 全体スケジュール

| Week | Day | 実装内容 | 成果物 |
|------|-----|---------|--------|
| 1 | 1-2 | CostSheet実装 | CostSheet CRUD完成 |
| 1-2 | 3-5 | MedicalRecord基本 | MedicalRecord CRUD（コスト項目なし） |
| 3 | 6-8 | CostItem + nested | コスト項目動的追加機能 |
| 4 | 9-10 | Active Storage | 画像アップロード機能 |
| 4 | 11 | Stimulus | 動的フォーム完成 |
| 5 | 12-13 | Tag機能 | タグ付け・フィルタリング |
| 5 | 14 | 検索強化 | Ransack統合 |
| 5 | 15 | E2Eテスト | システムスペック完成 |

### 3.2 TDD実装フロー（Phase 2から継承）

すべての機能をTDDで実装します:

```
1. Red: テスト作成（失敗することを確認）
2. Green: 最小限の実装（テストを通す）
3. Refactor: コード改善
4. Repeat: 次の機能へ
```

---

## 4. Week 1-2: 基盤整備

### 4.1 Day 1-2: CostSheet実装

#### 4.1.1 マイグレーション作成

```bash
rails generate model CostSheet \
  user:references \
  item_name:string \
  standard_price:decimal \
  category:string \
  description:text
```

**マイグレーションファイル編集:**

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_cost_sheets.rb
class CreateCostSheets < ActiveRecord::Migration[7.1]
  def change
    create_table :cost_sheets do |t|
      t.references :user, null: false, foreign_key: true
      t.string :item_name, null: false
      t.decimal :standard_price, precision: 10, scale: 2, null: false, default: 0.0
      t.string :category
      t.text :description

      t.timestamps
    end

    add_index :cost_sheets, :item_name
    add_index :cost_sheets, :category
  end
end
```

```bash
rails db:migrate
```

#### 4.1.2 モデルテスト作成（Red）

```ruby
# spec/models/cost_sheet_spec.rb
require 'rails_helper'

RSpec.describe CostSheet, type: :model do
  describe 'アソシエーション' do
    it { should belong_to(:user) }
  end

  describe 'バリデーション' do
    it { should validate_presence_of(:item_name) }
    it { should validate_presence_of(:standard_price) }
    it { should validate_numericality_of(:standard_price).is_greater_than_or_equal_to(0) }
    it { should validate_length_of(:item_name).is_at_most(100) }
  end

  describe 'enum' do
    it 'カテゴリが正しく定義されている' do
      expect(CostSheet.categories).to include(
        'treatment' => 'treatment',
        'medicine' => 'medicine',
        'supplies' => 'supplies',
        'other' => 'other'
      )
    end
  end

  describe 'スコープ' do
    let(:user) { create(:user) }
    let!(:cost_sheet1) { create(:cost_sheet, user: user, item_name: 'アイテムB') }
    let!(:cost_sheet2) { create(:cost_sheet, user: user, item_name: 'アイテムA') }

    it 'by_name: 名前順でソートされる' do
      expect(user.cost_sheets.by_name).to eq([cost_sheet2, cost_sheet1])
    end

    it 'recent: 作成日時降順でソートされる' do
      expect(user.cost_sheets.recent).to eq([cost_sheet2, cost_sheet1])
    end
  end

  describe 'メソッド' do
    let(:cost_sheet) { create(:cost_sheet, category: 'treatment') }

    it 'category_name: 日本語カテゴリ名を返す' do
      expect(cost_sheet.category_name).to eq('施術')
    end
  end
end
```

#### 4.1.3 FactoryBot定義

```ruby
# spec/factories/cost_sheets.rb
FactoryBot.define do
  factory :cost_sheet do
    user
    item_name { '眉毛アートメイク（2D）' }
    standard_price { 50000 }
    category { 'treatment' }
    description { '基本的な2Dアートメイク施術' }

    trait :medicine do
      item_name { '麻酔代' }
      standard_price { 5000 }
      category { 'medicine' }
    end

    trait :supplies do
      item_name { 'アフターケア用品' }
      standard_price { 3000 }
      category { 'supplies' }
    end
  end
end
```

#### 4.1.4 モデル実装（Green）

```ruby
# app/models/cost_sheet.rb
class CostSheet < ApplicationRecord
  # アソシエーション
  belongs_to :user
  has_many :cost_items, dependent: :nullify

  # 定数
  CATEGORIES = {
    'treatment' => '施術',
    'medicine' => '薬剤',
    'supplies' => '消耗品',
    'other' => 'その他'
  }.freeze

  # バリデーション
  validates :item_name, presence: true, length: { maximum: 100 }
  validates :standard_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :category, inclusion: { in: CATEGORIES.keys, allow_blank: true }

  # スコープ
  scope :by_name, -> { order(:item_name) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_category, ->(category) { where(category: category) }

  # クラスメソッド
  def self.categories
    CATEGORIES
  end

  # インスタンスメソッド
  def category_name
    CATEGORIES[category] || category
  end
end
```

```bash
# テスト実行
bundle exec rspec spec/models/cost_sheet_spec.rb
# 全て成功すればOK ✅
```

#### 4.1.5 コントローラーテスト作成

```ruby
# spec/requests/cost_sheets_spec.rb
require 'rails_helper'

RSpec.describe 'CostSheets', type: :request do
  let(:user) { create(:user) }
  let(:cost_sheet) { create(:cost_sheet, user: user) }

  before { sign_in user }

  describe 'GET /cost_sheets' do
    it '一覧ページが表示される' do
      get cost_sheets_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /cost_sheets/:id' do
    it '詳細ページが表示される' do
      get cost_sheet_path(cost_sheet)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /cost_sheets/new' do
    it '新規作成フォームが表示される' do
      get new_cost_sheet_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /cost_sheets' do
    context '有効なパラメータの場合' do
      let(:valid_params) do
        { cost_sheet: { item_name: 'テスト項目', standard_price: 10000, category: 'treatment' } }
      end

      it 'コストシートが作成される' do
        expect {
          post cost_sheets_path, params: valid_params
        }.to change(CostSheet, :count).by(1)
      end

      it 'リダイレクトされる' do
        post cost_sheets_path, params: valid_params
        expect(response).to redirect_to(cost_sheets_path)
      end
    end

    context '無効なパラメータの場合' do
      let(:invalid_params) do
        { cost_sheet: { item_name: '', standard_price: -100 } }
      end

      it 'コストシートが作成されない' do
        expect {
          post cost_sheets_path, params: invalid_params
        }.not_to change(CostSheet, :count)
      end

      it '422ステータスが返される' do
        post cost_sheets_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH /cost_sheets/:id' do
    context '有効なパラメータの場合' do
      let(:valid_params) do
        { cost_sheet: { item_name: '更新後の名前' } }
      end

      it 'コストシートが更新される' do
        patch cost_sheet_path(cost_sheet), params: valid_params
        cost_sheet.reload
        expect(cost_sheet.item_name).to eq('更新後の名前')
      end

      it 'リダイレクトされる' do
        patch cost_sheet_path(cost_sheet), params: valid_params
        expect(response).to redirect_to(cost_sheets_path)
      end
    end
  end

  describe 'DELETE /cost_sheets/:id' do
    it 'コストシートが削除される' do
      cost_sheet # 事前に作成
      expect {
        delete cost_sheet_path(cost_sheet)
      }.to change(CostSheet, :count).by(-1)
    end

    it 'リダイレクトされる' do
      delete cost_sheet_path(cost_sheet)
      expect(response).to redirect_to(cost_sheets_path)
    end
  end

  describe '認可' do
    let(:other_user) { create(:user) }
    let(:other_cost_sheet) { create(:cost_sheet, user: other_user) }

    it '他のユーザーのコストシートは表示できない' do
      expect {
        get cost_sheet_path(other_cost_sheet)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
```

#### 4.1.6 コントローラー実装

```ruby
# app/controllers/cost_sheets_controller.rb
class CostSheetsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_cost_sheet, only: [:show, :edit, :update, :destroy]

  def index
    @cost_sheets = current_user.cost_sheets.by_name.page(params[:page]).per(25)
  end

  def show
  end

  def new
    @cost_sheet = current_user.cost_sheets.build
  end

  def create
    @cost_sheet = current_user.cost_sheets.build(cost_sheet_params)

    if @cost_sheet.save
      redirect_to cost_sheets_path, notice: 'コストシートを登録しました'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @cost_sheet.update(cost_sheet_params)
      redirect_to cost_sheets_path, notice: 'コストシートを更新しました'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @cost_sheet.destroy
    redirect_to cost_sheets_path, notice: 'コストシートを削除しました'
  end

  private

  def set_cost_sheet
    @cost_sheet = current_user.cost_sheets.find(params[:id])
  end

  def cost_sheet_params
    params.require(:cost_sheet).permit(:item_name, :standard_price, :category, :description)
  end
end
```

#### 4.1.7 ルーティング追加

```ruby
# config/routes.rb
Rails.application.routes.draw do
  devise_for :users
  
  root 'facilities#index'
  
  resources :facilities
  resources :patients
  resources :questionnaires, only: [:new, :create, :edit, :update]
  resources :cost_sheets  # 追加
end
```

#### 4.1.8 ビュー作成

```erb
<!-- app/views/cost_sheets/index.html.erb -->
<div class="container mx-auto px-4 py-8">
  <div class="flex justify-between items-center mb-6">
    <h1 class="text-2xl font-bold">コストシート一覧</h1>
    <%= link_to '新規登録', new_cost_sheet_path, class: 'bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600' %>
  </div>

  <div class="bg-white shadow-md rounded-lg overflow-hidden">
    <table class="min-w-full">
      <thead class="bg-gray-100">
        <tr>
          <th class="px-6 py-3 text-left">項目名</th>
          <th class="px-6 py-3 text-left">カテゴリ</th>
          <th class="px-6 py-3 text-right">標準価格</th>
          <th class="px-6 py-3 text-center">操作</th>
        </tr>
      </thead>
      <tbody>
        <% @cost_sheets.each do |cost_sheet| %>
          <tr class="border-t">
            <td class="px-6 py-4"><%= cost_sheet.item_name %></td>
            <td class="px-6 py-4"><%= cost_sheet.category_name %></td>
            <td class="px-6 py-4 text-right">¥<%= number_with_delimiter(cost_sheet.standard_price) %></td>
            <td class="px-6 py-4 text-center">
              <%= link_to '編集', edit_cost_sheet_path(cost_sheet), class: 'text-blue-600 hover:underline mr-2' %>
              <%= button_to '削除', cost_sheet_path(cost_sheet), method: :delete, 
                  data: { confirm: '本当に削除しますか?' }, 
                  class: 'text-red-600 hover:underline' %>
            </td>
          </tr>
        <% end %>
      </tbody>
    </table>
  </div>

  <%= paginate @cost_sheets %>
</div>
```

```erb
<!-- app/views/cost_sheets/_form.html.erb -->
<%= form_with(model: cost_sheet, local: true, class: 'space-y-6') do |f| %>
  <% if cost_sheet.errors.any? %>
    <div class="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded">
      <ul>
        <% cost_sheet.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div>
    <%= f.label :item_name, '項目名', class: 'block text-sm font-medium text-gray-700 mb-2' %>
    <%= f.text_field :item_name, class: 'w-full px-3 py-2 border border-gray-300 rounded-md' %>
  </div>

  <div>
    <%= f.label :standard_price, '標準価格', class: 'block text-sm font-medium text-gray-700 mb-2' %>
    <%= f.number_field :standard_price, class: 'w-full px-3 py-2 border border-gray-300 rounded-md' %>
  </div>

  <div>
    <%= f.label :category, 'カテゴリ', class: 'block text-sm font-medium text-gray-700 mb-2' %>
    <%= f.select :category, 
        options_for_select(CostSheet::CATEGORIES.map { |k, v| [v, k] }, cost_sheet.category),
        { include_blank: '選択してください' },
        class: 'w-full px-3 py-2 border border-gray-300 rounded-md' %>
  </div>

  <div>
    <%= f.label :description, '説明', class: 'block text-sm font-medium text-gray-700 mb-2' %>
    <%= f.text_area :description, rows: 3, class: 'w-full px-3 py-2 border border-gray-300 rounded-md' %>
  </div>

  <div class="flex justify-end space-x-2">
    <%= link_to 'キャンセル', cost_sheets_path, class: 'px-4 py-2 border border-gray-300 rounded-md hover:bg-gray-50' %>
    <%= f.submit class: 'bg-blue-500 text-white px-4 py-2 rounded-md hover:bg-blue-600' %>
  </div>
<% end %>
```

```erb
<!-- app/views/cost_sheets/new.html.erb -->
<div class="container mx-auto px-4 py-8">
  <h1 class="text-2xl font-bold mb-6">コストシート新規登録</h1>
  <%= render 'form', cost_sheet: @cost_sheet %>
</div>
```

```erb
<!-- app/views/cost_sheets/edit.html.erb -->
<div class="container mx-auto px-4 py-8">
  <h1 class="text-2xl font-bold mb-6">コストシート編集</h1>
  <%= render 'form', cost_sheet: @cost_sheet %>
</div>
```

#### 4.1.9 日本語化

```yaml
# config/locales/ja.yml
ja:
  activerecord:
    models:
      cost_sheet: コストシート
    attributes:
      cost_sheet:
        item_name: 項目名
        standard_price: 標準価格
        category: カテゴリ
        description: 説明
```

#### 4.1.10 テスト実行・ブラウザ確認

```bash
# テスト実行
bundle exec rspec spec/models/cost_sheet_spec.rb
bundle exec rspec spec/requests/cost_sheets_spec.rb

# RuboCop実行
bundle exec rubocop -A

# サーバー起動
rails s

# ブラウザで確認
# http://localhost:3000/cost_sheets
# - 新規登録できるか
# - 一覧表示されるか
# - 編集・削除できるか
```

#### 4.1.11 シードデータ作成

```ruby
# db/seeds.rb に追加
if Rails.env.development?
  user = User.first || User.create!(email: 'demo@example.com', password: 'password')

  # コストシートサンプル
  cost_sheets_data = [
    { item_name: '眉毛アートメイク（2D）', standard_price: 50000, category: 'treatment', description: '基本的な2Dアートメイク' },
    { item_name: '眉毛アートメイク（3D）', standard_price: 60000, category: 'treatment', description: '立体的な3Dアートメイク' },
    { item_name: '眉毛アートメイク（4D）', standard_price: 70000, category: 'treatment', description: '最も自然な4Dアートメイク' },
    { item_name: 'リップアートメイク', standard_price: 70000, category: 'treatment' },
    { item_name: 'アイラインアートメイク', standard_price: 50000, category: 'treatment' },
    { item_name: '麻酔代', standard_price: 5000, category: 'medicine' },
    { item_name: 'アフターケア用品', standard_price: 3000, category: 'supplies' }
  ]

  cost_sheets_data.each do |data|
    user.cost_sheets.find_or_create_by!(item_name: data[:item_name]) do |cs|
      cs.assign_attributes(data)
    end
  end

  puts "✅ CostSheet シードデータ作成完了"
end
```

```bash
rails db:seed
```

#### 4.1.12 コミット・PR作成

```bash
git add .
git commit -m "feat(cost_sheet): コストシート機能実装

- CostSheetモデル実装（バリデーション、スコープ）
- CostSheetsコントローラー実装（CRUD）
- ビュー実装（一覧、フォーム）
- テスト実装（モデル、リクエスト）
- シードデータ追加

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

git push -u origin feature/phase3-cost-sheet

# GitHub上でPR作成
# タイトル: "Phase 3-A: コストシート機能実装"
# 本文:
# ## 概要
# Phase 3の最初の機能として、コストシート（料金テンプレート）管理機能を実装
#
# ## 実装内容
# - CostSheetモデル（CRUD、カテゴリ管理）
# - テスト完備（モデル、リクエスト）
# - シードデータ
#
# ## テスト結果
# - モデルスペック: 15/15成功
# - リクエストスペック: 18/18成功
# - RuboCop: 0違反
#
# ## 動作確認
# - ローカル環境でCRUD操作確認済み
```

---

### 4.2 Day 3-5: MedicalRecord基本実装

#### 4.2.1 マイグレーション作成

```bash
rails generate model MedicalRecord \
  user:references \
  patient:references \
  facility:references \
  treatment_date:date \
  treatment_content:text \
  counseling_content:text \
  total_amount:decimal
```

**マイグレーションファイル編集:**

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_medical_records.rb
class CreateMedicalRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :medical_records do |t|
      t.references :user, null: false, foreign_key: true
      t.references :patient, null: false, foreign_key: true
      t.references :facility, null: false, foreign_key: true
      t.date :treatment_date, null: false
      t.text :treatment_content
      t.text :counseling_content
      t.decimal :total_amount, precision: 10, scale: 2, null: false, default: 0.0

      t.timestamps
    end

    add_index :medical_records, [:user_id, :treatment_date]
    add_index :medical_records, [:facility_id, :treatment_date]
  end
end
```

```bash
rails db:migrate
```

#### 4.2.2 モデルテスト作成

```ruby
# spec/models/medical_record_spec.rb
require 'rails_helper'

RSpec.describe MedicalRecord, type: :model do
  describe 'アソシエーション' do
    it { should belong_to(:user) }
    it { should belong_to(:patient) }
    it { should belong_to(:facility) }
  end

  describe 'バリデーション' do
    it { should validate_presence_of(:treatment_date) }
    it { should validate_numericality_of(:total_amount).is_greater_than_or_equal_to(0) }

    it '施術日は過去または当日のみ' do
      record = build(:medical_record, treatment_date: Date.tomorrow)
      expect(record).not_to be_valid
      expect(record.errors[:treatment_date]).to be_present
    end

    it '施術日は当日ならOK' do
      record = build(:medical_record, treatment_date: Date.today)
      expect(record).to be_valid
    end
  end

  describe 'スコープ' do
    let(:user) { create(:user) }
    let!(:record1) { create(:medical_record, user: user, treatment_date: Date.today) }
    let!(:record2) { create(:medical_record, user: user, treatment_date: Date.yesterday) }

    it 'recent: 施術日降順でソートされる' do
      expect(user.medical_records.recent).to eq([record1, record2])
    end

    it 'by_date: 施術日昇順でソートされる' do
      expect(user.medical_records.by_date).to eq([record2, record1])
    end
  end
end
```

#### 4.2.3 FactoryBot定義

```ruby
# spec/factories/medical_records.rb
FactoryBot.define do
  factory :medical_record do
    user
    patient
    facility
    treatment_date { Date.today }
    treatment_content { 'アートメイク施術を実施' }
    counseling_content { 'カウンセリング実施' }
    total_amount { 50000 }

    trait :with_old_date do
      treatment_date { 1.month.ago }
    end
  end
end
```

#### 4.2.4 モデル実装

```ruby
# app/models/medical_record.rb
class MedicalRecord < ApplicationRecord
  # アソシエーション
  belongs_to :user
  belongs_to :patient
  belongs_to :facility

  # バリデーション
  validates :treatment_date, presence: true
  validates :treatment_date, comparison: { less_than_or_equal_to: -> { Date.today } }
  validates :total_amount, numericality: { greater_than_or_equal_to: 0 }

  # スコープ
  scope :recent, -> { order(treatment_date: :desc, created_at: :desc) }
  scope :by_date, -> { order(:treatment_date) }
  scope :in_period, ->(start_date, end_date) { where(treatment_date: start_date..end_date) }
  scope :by_facility, ->(facility_id) { where(facility_id: facility_id) }
  scope :by_patient, ->(patient_id) { where(patient_id: patient_id) }
end
```

**Patient, Facilityモデルに関連追加:**

```ruby
# app/models/patient.rb に追加
has_many :medical_records, dependent: :restrict_with_error

# app/models/facility.rb に追加
has_many :medical_records, dependent: :restrict_with_error

# app/models/user.rb に追加
has_many :medical_records, dependent: :destroy
```

#### 4.2.5 コントローラーテスト作成

```ruby
# spec/requests/medical_records_spec.rb
require 'rails_helper'

RSpec.describe 'MedicalRecords', type: :request do
  let(:user) { create(:user) }
  let(:patient) { create(:patient, user: user) }
  let(:facility) { create(:facility, user: user) }
  let(:medical_record) { create(:medical_record, user: user, patient: patient, facility: facility) }

  before { sign_in user }

  describe 'GET /medical_records' do
    it '一覧ページが表示される' do
      get medical_records_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /medical_records/:id' do
    it '詳細ページが表示される' do
      get medical_record_path(medical_record)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /medical_records/new' do
    it '新規作成フォームが表示される' do
      get new_medical_record_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /medical_records' do
    context '有効なパラメータの場合' do
      let(:valid_params) do
        {
          medical_record: {
            patient_id: patient.id,
            facility_id: facility.id,
            treatment_date: Date.today,
            treatment_content: 'テスト施術',
            total_amount: 50000
          }
        }
      end

      it 'カルテが作成される' do
        expect {
          post medical_records_path, params: valid_params
        }.to change(MedicalRecord, :count).by(1)
      end

      it 'リダイレクトされる' do
        post medical_records_path, params: valid_params
        expect(response).to redirect_to(medical_record_path(MedicalRecord.last))
      end
    end

    context '無効なパラメータの場合' do
      let(:invalid_params) do
        {
          medical_record: {
            patient_id: nil,
            facility_id: nil,
            treatment_date: Date.tomorrow
          }
        }
      end

      it 'カルテが作成されない' do
        expect {
          post medical_records_path, params: invalid_params
        }.not_to change(MedicalRecord, :count)
      end
    end
  end

  describe 'PATCH /medical_records/:id' do
    let(:valid_params) do
      { medical_record: { treatment_content: '更新後の内容' } }
    end

    it 'カルテが更新される' do
      patch medical_record_path(medical_record), params: valid_params
      medical_record.reload
      expect(medical_record.treatment_content).to eq('更新後の内容')
    end
  end

  describe 'DELETE /medical_records/:id' do
    it 'カルテが削除される' do
      medical_record # 事前に作成
      expect {
        delete medical_record_path(medical_record)
      }.to change(MedicalRecord, :count).by(-1)
    end
  end
end
```

#### 4.2.6 コントローラー実装

```ruby
# app/controllers/medical_records_controller.rb
class MedicalRecordsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_medical_record, only: [:show, :edit, :update, :destroy]
  before_action :load_form_data, only: [:new, :edit, :create, :update]

  def index
    @medical_records = current_user.medical_records
                                    .includes(:patient, :facility)
                                    .recent
                                    .page(params[:page])
                                    .per(25)
  end

  def show
  end

  def new
    @medical_record = current_user.medical_records.build(treatment_date: Date.today)
  end

  def create
    @medical_record = current_user.medical_records.build(medical_record_params)

    if @medical_record.save
      redirect_to @medical_record, notice: 'カルテを作成しました'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @medical_record.update(medical_record_params)
      redirect_to @medical_record, notice: 'カルテを更新しました'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @medical_record.destroy
    redirect_to medical_records_path, notice: 'カルテを削除しました'
  end

  private

  def set_medical_record
    @medical_record = current_user.medical_records.find(params[:id])
  end

  def load_form_data
    @patients = current_user.patients.order(:name)
    @facilities = current_user.facilities.order(:name)
  end

  def medical_record_params
    params.require(:medical_record).permit(
      :patient_id, :facility_id, :treatment_date,
      :treatment_content, :counseling_content, :total_amount
    )
  end
end
```

#### 4.2.7 ルーティング追加

```ruby
# config/routes.rb
resources :medical_records
```

#### 4.2.8 ビュー作成（基本版）

```erb
<!-- app/views/medical_records/index.html.erb -->
<div class="container mx-auto px-4 py-8">
  <div class="flex justify-between items-center mb-6">
    <h1 class="text-2xl font-bold">カルテ一覧</h1>
    <%= link_to '新規作成', new_medical_record_path, class: 'bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600' %>
  </div>

  <div class="bg-white shadow-md rounded-lg overflow-hidden">
    <table class="min-w-full">
      <thead class="bg-gray-100">
        <tr>
          <th class="px-6 py-3 text-left">施術日</th>
          <th class="px-6 py-3 text-left">患者名</th>
          <th class="px-6 py-3 text-left">施術場所</th>
          <th class="px-6 py-3 text-right">金額</th>
          <th class="px-6 py-3 text-center">操作</th>
        </tr>
      </thead>
      <tbody>
        <% @medical_records.each do |record| %>
          <tr class="border-t">
            <td class="px-6 py-4"><%= l(record.treatment_date) %></td>
            <td class="px-6 py-4"><%= record.patient.name %></td>
            <td class="px-6 py-4"><%= record.facility.name %></td>
            <td class="px-6 py-4 text-right">¥<%= number_with_delimiter(record.total_amount) %></td>
            <td class="px-6 py-4 text-center">
              <%= link_to '詳細', record, class: 'text-blue-600 hover:underline' %>
            </td>
          </tr>
        <% end %>
      </tbody>
    </table>
  </div>

  <%= paginate @medical_records %>
</div>
```

```erb
<!-- app/views/medical_records/_form.html.erb -->
<%= form_with(model: medical_record, local: true, class: 'space-y-6') do |f| %>
  <% if medical_record.errors.any? %>
    <div class="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded">
      <ul>
        <% medical_record.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
    <div>
      <%= f.label :patient_id, '患者', class: 'block text-sm font-medium text-gray-700 mb-2' %>
      <%= f.collection_select :patient_id, @patients, :id, :name,
          { prompt: '選択してください' },
          class: 'w-full px-3 py-2 border border-gray-300 rounded-md' %>
    </div>

    <div>
      <%= f.label :facility_id, '施術場所', class: 'block text-sm font-medium text-gray-700 mb-2' %>
      <%= f.collection_select :facility_id, @facilities, :id, :name,
          { prompt: '選択してください' },
          class: 'w-full px-3 py-2 border border-gray-300 rounded-md' %>
    </div>
  </div>

  <div>
    <%= f.label :treatment_date, '施術日', class: 'block text-sm font-medium text-gray-700 mb-2' %>
    <%= f.date_field :treatment_date, class: 'w-full px-3 py-2 border border-gray-300 rounded-md' %>
  </div>

  <div>
    <%= f.label :treatment_content, '施術内容', class: 'block text-sm font-medium text-gray-700 mb-2' %>
    <%= f.text_area :treatment_content, rows: 4, class: 'w-full px-3 py-2 border border-gray-300 rounded-md' %>
  </div>

  <div>
    <%= f.label :counseling_content, 'カウンセリング内容', class: 'block text-sm font-medium text-gray-700 mb-2' %>
    <%= f.text_area :counseling_content, rows: 4, class: 'w-full px-3 py-2 border border-gray-300 rounded-md' %>
  </div>

  <div>
    <%= f.label :total_amount, '合計金額', class: 'block text-sm font-medium text-gray-700 mb-2' %>
    <%= f.number_field :total_amount, class: 'w-full px-3 py-2 border border-gray-300 rounded-md' %>
    <p class="text-sm text-gray-500 mt-1">※コスト項目追加後は自動計算されます</p>
  </div>

  <div class="flex justify-end space-x-2">
    <%= link_to 'キャンセル', medical_records_path, class: 'px-4 py-2 border border-gray-300 rounded-md hover:bg-gray-50' %>
    <%= f.submit class: 'bg-blue-500 text-white px-4 py-2 rounded-md hover:bg-blue-600' %>
  </div>
<% end %>
```

```erb
<!-- app/views/medical_records/show.html.erb -->
<div class="container mx-auto px-4 py-8">
  <div class="bg-white shadow-md rounded-lg p-6">
    <div class="flex justify-between items-start mb-6">
      <h1 class="text-2xl font-bold">カルテ詳細</h1>
      <div class="space-x-2">
        <%= link_to '編集', edit_medical_record_path(@medical_record), class: 'bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600' %>
        <%= button_to '削除', @medical_record, method: :delete,
            data: { confirm: '本当に削除しますか?' },
            class: 'bg-red-500 text-white px-4 py-2 rounded hover:bg-red-600' %>
      </div>
    </div>

    <dl class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <div>
        <dt class="font-semibold text-gray-700">施術日</dt>
        <dd><%= l(@medical_record.treatment_date) %></dd>
      </div>

      <div>
        <dt class="font-semibold text-gray-700">患者名</dt>
        <dd><%= link_to @medical_record.patient.name, @medical_record.patient, class: 'text-blue-600 hover:underline' %></dd>
      </div>

      <div>
        <dt class="font-semibold text-gray-700">施術場所</dt>
        <dd><%= link_to @medical_record.facility.name, @medical_record.facility, class: 'text-blue-600 hover:underline' %></dd>
      </div>

      <div>
        <dt class="font-semibold text-gray-700">合計金額</dt>
        <dd class="text-xl font-bold">¥<%= number_with_delimiter(@medical_record.total_amount) %></dd>
      </div>

      <div class="md:col-span-2">
        <dt class="font-semibold text-gray-700">施術内容</dt>
        <dd class="whitespace-pre-wrap"><%= @medical_record.treatment_content %></dd>
      </div>

      <div class="md:col-span-2">
        <dt class="font-semibold text-gray-700">カウンセリング内容</dt>
        <dd class="whitespace-pre-wrap"><%= @medical_record.counseling_content %></dd>
      </div>
    </dl>

    <div class="mt-6">
      <%= link_to '一覧に戻る', medical_records_path, class: 'text-blue-600 hover:underline' %>
    </div>
  </div>
</div>
```

#### 4.2.9 日本語化

```yaml
# config/locales/ja.yml に追加
  medical_record:
    treatment_date: 施術日
    patient: 患者
    facility: 施術場所
    treatment_content: 施術内容
    counseling_content: カウンセリング内容
    total_amount: 合計金額
```

#### 4.2.10 テスト・ブラウザ確認・コミット

```bash
# テスト実行
bundle exec rspec spec/models/medical_record_spec.rb
bundle exec rspec spec/requests/medical_records_spec.rb

# RuboCop
bundle exec rubocop -A

# ブラウザで動作確認
rails s
# http://localhost:3000/medical_records

# コミット
git add .
git commit -m "feat(medical_record): カルテ基本機能実装

- MedicalRecordモデル実装
- CRUD機能実装
- Patient, Facilityとの関連
- テスト完備

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

git push
```

---

### 4.3 Day 6 (30分): 問診票チェックボックスUI有効化

**Phase 2で実装済みのチェックボックスUIを有効化する簡単な作業です。**

#### 4.3.1 背景

Phase 2で問診票のチェックボックスUI（`_form_checkbox.html.erb`）を実装しましたが、
フィーチャーフラグ`USE_CHECKBOX_UI = false`で無効化していました。
カルテ機能が実装されたため、問診票UIを改善します。

#### 4.3.2 フィーチャーフラグ変更

**app/controllers/questionnaires_controller.rb**

```ruby
class QuestionnairesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_patient
  before_action :set_questionnaire, only: %i[show edit update destroy]

  # フィーチャーフラグ: Phase 3で有効化 ✅
  USE_CHECKBOX_UI = true  # false から true に変更

  def new
    @questionnaire = @patient.build_questionnaire
    @use_checkbox_ui = USE_CHECKBOX_UI
  end

  def edit
    @use_checkbox_ui = USE_CHECKBOX_UI
  end

  # ...残りは変更なし
end
```

**変更内容**: たった1行の変更です！

```diff
- USE_CHECKBOX_UI = false
+ USE_CHECKBOX_UI = true
```

#### 4.3.3 カルテから問診票へのリンク追加（任意）

カルテページに問診票へのリンクを追加すると便利です。

**app/views/medical_records/show.html.erb**

```erb
<!-- 既存のカルテ詳細表示 -->

<!-- 問診票リンク追加 -->
<div class="mt-6 p-4 bg-blue-50 rounded-lg">
  <h3 class="text-lg font-semibold mb-2">📋 関連情報</h3>
  <% if @medical_record.patient.questionnaire.present? %>
    <%= link_to "問診票を確認",
                patient_questionnaire_path(@medical_record.patient, @medical_record.patient.questionnaire),
                class: "text-blue-600 hover:text-blue-800 underline" %>
  <% else %>
    <%= link_to "問診票を作成",
                new_patient_questionnaire_path(@medical_record.patient),
                class: "text-blue-600 hover:text-blue-800 underline" %>
  <% end %>
</div>
```

#### 4.3.4 テスト実行

既存の問診票テストを実行してチェックボックスUIが正常動作することを確認:

```bash
# 問診票関連の全テスト実行
bundle exec rspec spec/models/questionnaire_spec.rb
bundle exec rspec spec/requests/questionnaires_spec.rb
bundle exec rspec spec/system/questionnaires_spec.rb

# RuboCop確認
bundle exec rubocop -A
```

**期待結果**:
- 全テスト成功 ✅
- RuboCop 0違反 ✅

#### 4.3.5 ブラウザ動作確認

```bash
rails server
```

1. **患者詳細ページ**から「問診票作成」をクリック
2. **チェックボックスUI**が表示されることを確認
   - 既往歴: 大きなチェックボックス
   - アレルギー: 大きなチェックボックス
   - 服薬歴: 大きなチェックボックス
3. 各項目にチェックを入れて**保存**
4. 問診票詳細ページで内容が正しく表示されることを確認
5. **既存データ**（テキストエリア版で作成したもの）も正常表示されることを確認

#### 4.3.6 確認ポイント

- ✅ チェックボックスUIが表示される
- ✅ iPadでタッチ操作しやすい
- ✅ 保存が正常動作
- ✅ 既存データとの後方互換性あり
- ✅ カルテページから問診票へアクセス可能（リンク追加した場合）

#### 4.3.7 コミット

```bash
git add .
git commit -m "feat(questionnaire): チェックボックスUI有効化

- USE_CHECKBOX_UIフラグをtrueに変更
- Phase 2で実装済みのチェックボックスUIを有効化
- iPadでの入力操作性向上
- カルテから問診票へのリンク追加（任意）
- 既存データとの後方互換性維持

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
```

**所要時間**: 30分程度（テスト含む）

---

## 5. Week 3: コスト統合

### 5.1 Day 7-9: CostItem + nested attributes実装

**この部分は最も複雑です。TDDで慎重に実装します。**

#### 5.1.1 CostItemモデル作成

```bash
rails generate model CostItem \
  medical_record:references \
  cost_sheet:references \
  item_name:string \
  unit_price:decimal \
  quantity:integer \
  subtotal:decimal \
  notes:text
```

**マイグレーション編集:**

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_cost_items.rb
class CreateCostItems < ActiveRecord::Migration[7.1]
  def change
    create_table :cost_items do |t|
      t.references :medical_record, null: false, foreign_key: true
      t.references :cost_sheet, null: true, foreign_key: true
      t.string :item_name, null: false
      t.decimal :unit_price, precision: 10, scale: 2, null: false, default: 0.0
      t.integer :quantity, null: false, default: 1
      t.decimal :subtotal, precision: 10, scale: 2, null: false, default: 0.0
      t.text :notes

      t.timestamps
    end
  end
end
```

```bash
rails db:migrate
```

#### 5.1.2 CostItemモデルテスト

```ruby
# spec/models/cost_item_spec.rb
require 'rails_helper'

RSpec.describe CostItem, type: :model do
  describe 'アソシエーション' do
    it { should belong_to(:medical_record) }
    it { should belong_to(:cost_sheet).optional }
  end

  describe 'バリデーション' do
    it { should validate_presence_of(:item_name) }
    it { should validate_presence_of(:unit_price) }
    it { should validate_presence_of(:quantity) }
    it { should validate_numericality_of(:unit_price).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:quantity).is_greater_than(0).only_integer }
    it { should validate_numericality_of(:subtotal).is_greater_than_or_equal_to(0) }
  end

  describe 'コールバック' do
    describe 'calculate_subtotal' do
      let(:cost_item) { build(:cost_item, unit_price: 10000, quantity: 2) }

      it '保存前に小計が計算される' do
        cost_item.save
        expect(cost_item.subtotal).to eq(20000)
      end

      it '単価変更時に再計算される' do
        cost_item.save
        cost_item.update(unit_price: 15000)
        expect(cost_item.subtotal).to eq(30000)
      end

      it '数量変更時に再計算される' do
        cost_item.save
        cost_item.update(quantity: 3)
        expect(cost_item.subtotal).to eq(30000)
      end
    end

    describe 'update_medical_record_total' do
      let(:medical_record) { create(:medical_record) }
      let!(:cost_item1) { create(:cost_item, medical_record: medical_record, unit_price: 50000, quantity: 1) }

      it 'コスト項目追加時にカルテの合計金額が更新される' do
        expect(medical_record.reload.total_amount).to eq(50000)

        create(:cost_item, medical_record: medical_record, unit_price: 5000, quantity: 1)
        expect(medical_record.reload.total_amount).to eq(55000)
      end

      it 'コスト項目削除時にカルテの合計金額が更新される' do
        cost_item1.destroy
        expect(medical_record.reload.total_amount).to eq(0)
      end
    end
  end
end
```

#### 5.1.3 CostItemモデル実装

```ruby
# app/models/cost_item.rb
class CostItem < ApplicationRecord
  # アソシエーション
  belongs_to :medical_record
  belongs_to :cost_sheet, optional: true

  # バリデーション
  validates :item_name, presence: true
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :subtotal, numericality: { greater_than_or_equal_to: 0 }

  # コールバック
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

#### 5.1.4 MedicalRecordモデルにnested attributes追加

```ruby
# app/models/medical_record.rb に追加

# アソシエーション
has_many :cost_items, dependent: :destroy

# Nested attributes
accepts_nested_attributes_for :cost_items, allow_destroy: true, reject_if: :all_blank

# コールバック
after_save :update_total_amount

# メソッド
def update_total_amount
  new_total = cost_items.sum(:subtotal)
  update_column(:total_amount, new_total) if total_amount != new_total
end
```

#### 5.1.5 MedicalRecordモデルのnested attributesテスト

```ruby
# spec/models/medical_record_spec.rb に追加

describe 'nested attributes' do
  let(:user) { create(:user) }
  let(:patient) { create(:patient, user: user) }
  let(:facility) { create(:facility, user: user) }

  it 'コスト項目と一緒に作成できる' do
    record = MedicalRecord.create!(
      user: user,
      patient: patient,
      facility: facility,
      treatment_date: Date.today,
      cost_items_attributes: [
        { item_name: '施術A', unit_price: 50000, quantity: 1 },
        { item_name: '施術B', unit_price: 10000, quantity: 2 }
      ]
    )

    expect(record.cost_items.count).to eq(2)
    expect(record.total_amount).to eq(70000)
  end

  it 'コスト項目を追加できる' do
    record = create(:medical_record, user: user, patient: patient, facility: facility)
    record.update(
      cost_items_attributes: [
        { item_name: '追加項目', unit_price: 5000, quantity: 1 }
      ]
    )

    expect(record.cost_items.count).to eq(1)
    expect(record.total_amount).to eq(5000)
  end

  it 'コスト項目を削除できる' do
    cost_item = create(:cost_item, medical_record: create(:medical_record), unit_price: 10000)
    record = cost_item.medical_record

    record.update(
      cost_items_attributes: [
        { id: cost_item.id, _destroy: '1' }
      ]
    )

    expect(record.cost_items.count).to eq(0)
    expect(record.total_amount).to eq(0)
  end
end
```

#### 5.1.6 FactoryBot定義

```ruby
# spec/factories/cost_items.rb
FactoryBot.define do
  factory :cost_item do
    medical_record
    cost_sheet { nil }
    item_name { '眉毛アートメイク' }
    unit_price { 50000 }
    quantity { 1 }
    subtotal { 50000 }

    trait :from_template do
      association :cost_sheet
      item_name { cost_sheet&.item_name || '施術項目' }
      unit_price { cost_sheet&.standard_price || 50000 }
    end
  end
end
```

#### 5.1.7 コントローラーのStrong Parameters更新

```ruby
# app/controllers/medical_records_controller.rb

def medical_record_params
  params.require(:medical_record).permit(
    :patient_id, :facility_id, :treatment_date,
    :treatment_content, :counseling_content,
    cost_items_attributes: [
      :id, :cost_sheet_id, :item_name, :unit_price, :quantity, :notes, :_destroy
    ]
  )
end

# before_action :load_form_data に追加
def load_form_data
  @patients = current_user.patients.order(:name)
  @facilities = current_user.facilities.order(:name)
  @cost_sheets = current_user.cost_sheets.by_category.order(:item_name) # 追加
end
```

#### 5.1.8 フォーム更新（nested fields追加）

```erb
<!-- app/views/medical_records/_form.html.erb -->
<!-- 既存のフォームに以下を追加 -->

<div class="border-t pt-6 mt-6">
  <h3 class="text-lg font-semibold mb-4">コスト項目</h3>
  
  <div id="cost-items" class="space-y-4">
    <%= f.fields_for :cost_items do |cost_item_form| %>
      <%= render 'cost_item_fields', f: cost_item_form, cost_sheets: @cost_sheets %>
    <% end %>
  </div>

  <div class="mt-4">
    <%= link_to_add_association 'コスト項目を追加', f, :cost_items,
        class: 'bg-green-500 text-white px-4 py-2 rounded hover:bg-green-600',
        data: { association_insertion_node: '#cost-items', association_insertion_method: 'append' },
        partial: 'cost_item_fields', render_options: { locals: { cost_sheets: @cost_sheets } } %>
  </div>

  <div class="mt-6 text-right">
    <span class="text-xl font-bold">合計: </span>
    <span id="total-amount" class="text-2xl font-bold text-blue-600">¥0</span>
  </div>
</div>
```

```erb
<!-- app/views/medical_records/_cost_item_fields.html.erb -->
<div class="nested-fields border border-gray-300 rounded-lg p-4 bg-gray-50">
  <div class="grid grid-cols-1 md:grid-cols-12 gap-4">
    <!-- コストシート選択 -->
    <div class="md:col-span-3">
      <%= f.label :cost_sheet_id, 'テンプレート', class: 'block text-sm font-medium text-gray-700 mb-1' %>
      <%= f.collection_select :cost_sheet_id, cost_sheets, :id, :item_name,
          { include_blank: '選択...' },
          class: 'w-full px-3 py-2 border border-gray-300 rounded-md text-sm cost-sheet-select' %>
    </div>

    <!-- 項目名 -->
    <div class="md:col-span-3">
      <%= f.label :item_name, '項目名', class: 'block text-sm font-medium text-gray-700 mb-1' %>
      <%= f.text_field :item_name, class: 'w-full px-3 py-2 border border-gray-300 rounded-md text-sm item-name' %>
    </div>

    <!-- 単価 -->
    <div class="md:col-span-2">
      <%= f.label :unit_price, '単価', class: 'block text-sm font-medium text-gray-700 mb-1' %>
      <%= f.number_field :unit_price, class: 'w-full px-3 py-2 border border-gray-300 rounded-md text-sm unit-price' %>
    </div>

    <!-- 数量 -->
    <div class="md:col-span-2">
      <%= f.label :quantity, '数量', class: 'block text-sm font-medium text-gray-700 mb-1' %>
      <%= f.number_field :quantity, value: f.object.quantity || 1, class: 'w-full px-3 py-2 border border-gray-300 rounded-md text-sm quantity' %>
    </div>

    <!-- 小計 -->
    <div class="md:col-span-1">
      <label class="block text-sm font-medium text-gray-700 mb-1">小計</label>
      <div class="subtotal-display text-lg font-semibold text-right py-2">¥0</div>
    </div>

    <!-- 削除ボタン -->
    <div class="md:col-span-1 flex items-end">
      <%= link_to_remove_association '削除', f, class: 'text-red-600 hover:text-red-800 text-sm' %>
    </div>
  </div>

  <!-- 備考 -->
  <div class="mt-2">
    <%= f.label :notes, '備考', class: 'block text-sm font-medium text-gray-700 mb-1' %>
    <%= f.text_field :notes, class: 'w-full px-3 py-2 border border-gray-300 rounded-md text-sm', placeholder: '割引理由など' %>
  </div>
end
```

**注意:** `link_to_add_association` と `link_to_remove_association` は `cocoon` gem を使用します。

```ruby
# Gemfile に追加
gem 'cocoon', '~> 1.2'
```

```bash
bundle install
```

```js
// app/javascript/application.js に追加
import "@nathanvda/cocoon"
```

#### 5.1.9 テスト実行・ブラウザ確認

```bash
bundle exec rspec spec/models/cost_item_spec.rb
bundle exec rspec spec/models/medical_record_spec.rb
bundle exec rubocop -A

# ブラウザで確認
rails s
# カルテ作成時にコスト項目を追加できるか確認
```

#### 5.1.10 コミット

```bash
git add .
git commit -m "feat(cost_item): コスト項目とnested attributes実装

- CostItemモデル実装（小計自動計算）
- MedicalRecordにnested attributes設定
- カルテ合計金額の自動更新
- 動的フォーム実装（cocoon使用）
- テスト完備

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

git push
```

---

## 6. Week 4: フロントエンド強化

### 6.1 Day 11-12: Active Storage実装

#### 6.1.1 Active Storageインストール

```bash
rails active_storage:install
rails db:migrate
```

#### 6.1.2 ストレージ設定

```yaml
# config/storage.yml

# 開発環境: ローカルストレージ
local:
  service: Disk
  root: <%= Rails.root.join("storage") %>

# 本番環境: Cloudflare R2（Phase 4で設定）
cloudflare_r2:
  service: S3
  access_key_id: <%= ENV['R2_ACCESS_KEY_ID'] %>
  secret_access_key: <%= ENV['R2_SECRET_ACCESS_KEY'] %>
  region: auto
  bucket: <%= ENV['R2_BUCKET_NAME'] %>
  endpoint: <%= ENV['R2_ENDPOINT'] %>
```

```ruby
# config/environments/development.rb
config.active_storage.service = :local

# config/environments/production.rb
config.active_storage.service = :cloudflare_r2
```

#### 6.1.3 MedicalRecordモデルに画像添付追加

```ruby
# app/models/medical_record.rb に追加

# Active Storage
has_many_attached :photos

# バリデーション
validate :photos_count_limit
validate :photos_size_limit
validate :photos_content_type

private

def photos_count_limit
  if photos.count > 5
    errors.add(:photos, '写真は最大5枚までアップロードできます')
  end
end

def photos_size_limit
  photos.each do |photo|
    if photo.blob&.byte_size && photo.blob.byte_size > 10.megabytes
      errors.add(:photos, "#{photo.filename}のサイズが10MBを超えています")
    end
  end
end

def photos_content_type
  photos.each do |photo|
    unless photo.content_type.in?(%w[image/jpeg image/png])
      errors.add(:photos, "#{photo.filename}はJPEGまたはPNG形式ではありません")
    end
  end
end
```

#### 6.1.4 画像アップロードテスト

```ruby
# spec/models/medical_record_spec.rb に追加

describe '画像アップロード' do
  let(:record) { create(:medical_record) }

  it '画像を添付できる' do
    record.photos.attach(
      io: File.open(Rails.root.join('spec/fixtures/files/sample.jpg')),
      filename: 'sample.jpg',
      content_type: 'image/jpeg'
    )

    expect(record.photos).to be_attached
    expect(record.photos.count).to eq(1)
  end

  it '最大5枚まで添付できる' do
    5.times do |i|
      record.photos.attach(
        io: File.open(Rails.root.join('spec/fixtures/files/sample.jpg')),
        filename: "sample#{i}.jpg",
        content_type: 'image/jpeg'
      )
    end

    expect(record.photos.count).to eq(5)
    expect(record).to be_valid
  end

  it '6枚目はエラーになる' do
    6.times do |i|
      record.photos.attach(
        io: File.open(Rails.root.join('spec/fixtures/files/sample.jpg')),
        filename: "sample#{i}.jpg",
        content_type: 'image/jpeg'
      )
    end

    expect(record).not_to be_valid
    expect(record.errors[:photos]).to include('写真は最大5枚までアップロードできます')
  end
end
```

**テスト用画像ファイル作成:**

```bash
mkdir -p spec/fixtures/files
# 1x1ピクセルのJPEG画像を作成（テスト用）
convert -size 1x1 xc:white spec/fixtures/files/sample.jpg
```

#### 6.1.5 コントローラーのStrong Parameters更新

```ruby
# app/controllers/medical_records_controller.rb

def medical_record_params
  params.require(:medical_record).permit(
    :patient_id, :facility_id, :treatment_date,
    :treatment_content, :counseling_content,
    photos: [],  # 追加
    cost_items_attributes: [
      :id, :cost_sheet_id, :item_name, :unit_price, :quantity, :notes, :_destroy
    ]
  )
end
```

#### 6.1.6 フォームに画像アップロード追加

```erb
<!-- app/views/medical_records/_form.html.erb に追加 -->

<div class="border-t pt-6 mt-6">
  <h3 class="text-lg font-semibold mb-4">施術写真</h3>
  
  <%= f.label :photos, '写真（最大5枚、各10MB以下）', class: 'block text-sm font-medium text-gray-700 mb-2' %>
  <%= f.file_field :photos, multiple: true, accept: 'image/jpeg,image/png', 
      class: 'w-full px-3 py-2 border border-gray-300 rounded-md' %>
  
  <% if medical_record.photos.attached? %>
    <div class="mt-4 grid grid-cols-2 md:grid-cols-4 gap-4">
      <% medical_record.photos.each do |photo| %>
        <div class="relative">
          <%= image_tag photo.variant(resize_to_limit: [200, 200]), class: 'rounded-lg shadow' %>
          <%= button_to '削除', remove_photo_medical_record_path(medical_record, photo_id: photo.id), 
              method: :delete, 
              data: { confirm: '削除しますか?' },
              class: 'absolute top-1 right-1 bg-red-500 text-white px-2 py-1 rounded text-xs' %>
        </div>
      <% end %>
    </div>
  <% end %>
</div>
```

#### 6.1.7 画像削除アクション追加

```ruby
# app/controllers/medical_records_controller.rb に追加

before_action :set_medical_record, only: [:show, :edit, :update, :destroy, :remove_photo]

def remove_photo
  photo = @medical_record.photos.find(params[:photo_id])
  photo.purge
  redirect_to edit_medical_record_path(@medical_record), notice: '写真を削除しました'
end
```

```ruby
# config/routes.rb に追加
resources :medical_records do
  member do
    delete :remove_photo
  end
end
```

#### 6.1.8 詳細ページに画像表示追加

```erb
<!-- app/views/medical_records/show.html.erb に追加 -->

<% if @medical_record.photos.attached? %>
  <div class="mt-6">
    <h3 class="font-semibold text-gray-700 mb-2">施術写真</h3>
    <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
      <% @medical_record.photos.each do |photo| %>
        <%= link_to image_tag(photo.variant(resize_to_limit: [200, 200]), class: 'rounded-lg shadow cursor-pointer'),
            rails_blob_path(photo, disposition: 'attachment'), target: '_blank' %>
      <% end %>
    </div>
  </div>
<% end %>
```

#### 6.1.9 テスト・ブラウザ確認

```bash
bundle exec rspec spec/models/medical_record_spec.rb
bundle exec rubocop -A

rails s
# カルテ作成時に画像をアップロードできるか確認
```

---

### 6.2 Day 13: Stimulusコントローラー実装

#### 6.2.1 cost-items_controller作成

```javascript
// app/javascript/controllers/cost_items_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "total"]
  static values = {
    costSheets: Object,
    maxItems: { type: Number, default: 10 }
  }

  connect() {
    console.log("Cost items controller connected")
    this.calculateTotal()
  }

  // コストシート選択時
  selectCostSheet(event) {
    const select = event.target
    const costSheetId = select.value

    if (!costSheetId) return

    const costSheet = this.costSheetsValue[costSheetId]
    if (!costSheet) return

    const item = select.closest('.nested-fields')
    const nameInput = item.querySelector('.item-name')
    const priceInput = item.querySelector('.unit-price')

    if (nameInput) nameInput.value = costSheet.item_name
    if (priceInput) priceInput.value = costSheet.standard_price

    this.calculateTotal()
  }

  // 金額計算
  calculateTotal() {
    let total = 0

    const items = this.element.querySelectorAll('.nested-fields:not([style*="display: none"])')
    items.forEach(item => {
      const price = parseFloat(item.querySelector('.unit-price')?.value) || 0
      const qty = parseInt(item.querySelector('.quantity')?.value) || 1
      const subtotal = price * qty

      const subtotalDisplay = item.querySelector('.subtotal-display')
      if (subtotalDisplay) {
        subtotalDisplay.textContent = `¥${subtotal.toLocaleString()}`
      }

      total += subtotal
    })

    if (this.hasTotalTarget) {
      this.totalTarget.textContent = `¥${total.toLocaleString()}`
    }
  }

  // 入力値変更時
  updateTotal(event) {
    this.calculateTotal()
  }

  // コスト項目追加時（cocoonのコールバック）
  itemAdded(event) {
    this.calculateTotal()
  }

  // コスト項目削除時（cocoonのコールバック）
  itemRemoved(event) {
    this.calculateTotal()
  }
}
```

#### 6.2.2 フォームにStimulus属性追加

```erb
<!-- app/views/medical_records/_form.html.erb -->

<div data-controller="cost-items" 
     data-cost-items-cost-sheets-value="<%= @cost_sheets.to_json(only: [:id, :item_name, :standard_price]) %>"
     class="border-t pt-6 mt-6">
  
  <h3 class="text-lg font-semibold mb-4">コスト項目</h3>
  
  <div id="cost-items" data-cost-items-target="container" class="space-y-4">
    <%= f.fields_for :cost_items do |cost_item_form| %>
      <%= render 'cost_item_fields', f: cost_item_form, cost_sheets: @cost_sheets %>
    <% end %>
  </div>

  <div class="mt-4">
    <%= link_to_add_association 'コスト項目を追加', f, :cost_items,
        class: 'bg-green-500 text-white px-4 py-2 rounded hover:bg-green-600',
        data: { 
          association_insertion_node: '#cost-items', 
          association_insertion_method: 'append',
          action: 'cocoon:after-insert->cost-items#itemAdded cocoon:after-remove->cost-items#itemRemoved'
        },
        partial: 'cost_item_fields', 
        render_options: { locals: { cost_sheets: @cost_sheets } } %>
  </div>

  <div class="mt-6 text-right">
    <span class="text-xl font-bold">合計: </span>
    <span data-cost-items-target="total" class="text-2xl font-bold text-blue-600">¥0</span>
  </div>
</div>
```

```erb
<!-- app/views/medical_records/_cost_item_fields.html.erb -->
<!-- 各入力フィールドに data-action 追加 -->

<div class="md:col-span-3">
  <%= f.label :cost_sheet_id, 'テンプレート', class: 'block text-sm font-medium text-gray-700 mb-1' %>
  <%= f.collection_select :cost_sheet_id, cost_sheets, :id, :item_name,
      { include_blank: '選択...' },
      class: 'w-full px-3 py-2 border border-gray-300 rounded-md text-sm cost-sheet-select',
      data: { action: 'change->cost-items#selectCostSheet' } %>
</div>

<!-- 単価と数量にもdata-action追加 -->
<div class="md:col-span-2">
  <%= f.label :unit_price, '単価', class: 'block text-sm font-medium text-gray-700 mb-1' %>
  <%= f.number_field :unit_price, 
      class: 'w-full px-3 py-2 border border-gray-300 rounded-md text-sm unit-price',
      data: { action: 'input->cost-items#updateTotal' } %>
</div>

<div class="md:col-span-2">
  <%= f.label :quantity, '数量', class: 'block text-sm font-medium text-gray-700 mb-1' %>
  <%= f.number_field :quantity, value: f.object.quantity || 1,
      class: 'w-full px-3 py-2 border border-gray-300 rounded-md text-sm quantity',
      data: { action: 'input->cost-items#updateTotal' } %>
</div>
```

#### 6.2.3 ブラウザで動作確認

```bash
rails s

# 確認項目:
# 1. コストシート選択 → 項目名・単価が自動入力される
# 2. 単価・数量変更 → 小計が自動計算される
# 3. コスト項目追加・削除 → 合計金額が自動更新される
# 4. フォーム送信 → データが正しく保存される
```

#### 6.2.4 コミット

```bash
git add .
git commit -m "feat(stimulus): 動的コストフォーム実装

- cost-items_controller実装（Stimulus）
- コストシート選択で自動入力
- 金額の自動計算
- Active Storage画像アップロード実装

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

git push
```

---

## 7. Week 5: 完成

### 7.1 Day 14: Tag機能実装

#### 7.1.1 Tagモデル作成

```bash
rails generate model Tag user:references name:string color:string
rails generate model MedicalRecordTag medical_record:references tag:references
```

**マイグレーション編集:**

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_tags.rb
class CreateTags < ActiveRecord::Migration[7.1]
  def change
    create_table :tags do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :color, default: '#3B82F6'

      t.timestamps
    end

    add_index :tags, [:user_id, :name], unique: true
  end
end

# db/migrate/YYYYMMDDHHMMSS_create_medical_record_tags.rb
class CreateMedicalRecordTags < ActiveRecord::Migration[7.1]
  def change
    create_table :medical_record_tags do |t|
      t.references :medical_record, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end

    add_index :medical_record_tags, [:medical_record_id, :tag_id], unique: true
  end
end
```

```bash
rails db:migrate
```

#### 7.1.2 Tagモデル実装

```ruby
# app/models/tag.rb
class Tag < ApplicationRecord
  belongs_to :user
  has_many :medical_record_tags, dependent: :destroy
  has_many :medical_records, through: :medical_record_tags

  validates :name, presence: true, length: { maximum: 50 }
  validates :name, uniqueness: { scope: :user_id }
  validates :color, format: { with: /\A#[0-9A-F]{6}\z/i, allow_blank: true }

  scope :by_name, -> { order(:name) }
end

# app/models/medical_record_tag.rb
class MedicalRecordTag < ApplicationRecord
  belongs_to :medical_record
  belongs_to :tag
end

# app/models/medical_record.rb に追加
has_many :medical_record_tags, dependent: :destroy
has_many :tags, through: :medical_record_tags

# app/models/user.rb に追加
has_many :tags, dependent: :destroy
```

#### 7.1.3 タグ付け機能実装（簡易版）

カルテフォームにタグ入力フィールドを追加:

```erb
<!-- app/views/medical_records/_form.html.erb に追加 -->

<div>
  <%= f.label :tag_names, 'タグ（カンマ区切り）', class: 'block text-sm font-medium text-gray-700 mb-2' %>
  <%= text_field_tag :tag_names, 
      medical_record.tags.map(&:name).join(', '),
      class: 'w-full px-3 py-2 border border-gray-300 rounded-md',
      placeholder: '例: リップ, 2D, モニター価格' %>
</div>
```

**コントローラーでタグ処理:**

```ruby
# app/controllers/medical_records_controller.rb

def create
  @medical_record = current_user.medical_records.build(medical_record_params)

  if @medical_record.save
    process_tags if params[:tag_names].present?
    redirect_to @medical_record, notice: 'カルテを作成しました'
  else
    render :new, status: :unprocessable_entity
  end
end

def update
  if @medical_record.update(medical_record_params)
    process_tags if params[:tag_names].present?
    redirect_to @medical_record, notice: 'カルテを更新しました'
  else
    render :edit, status: :unprocessable_entity
  end
end

private

def process_tags
  tag_names = params[:tag_names].split(',').map(&:strip).reject(&:blank?)
  @medical_record.tags.clear

  tag_names.each do |name|
    tag = current_user.tags.find_or_create_by(name: name)
    @medical_record.tags << tag unless @medical_record.tags.include?(tag)
  end
end
```

---

### 7.2 Day 15: 検索機能強化（Ransack）

#### 7.2.1 Ransackセットアップ

```ruby
# Gemfileに既に追加済み
gem 'ransack', '~> 4.0'
```

```bash
bundle install
```

#### 7.2.2 コントローラーに検索追加

```ruby
# app/controllers/medical_records_controller.rb

def index
  @q = current_user.medical_records.ransack(params[:q])
  @medical_records = @q.result
                       .includes(:patient, :facility, :tags)
                       .recent
                       .page(params[:page])
                       .per(25)
end
```

#### 7.2.3 検索フォーム作成

```erb
<!-- app/views/medical_records/index.html.erb -->

<div class="bg-white shadow-md rounded-lg p-4 mb-6">
  <%= search_form_for @q, url: medical_records_path, method: :get do |f| %>
    <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
      <div>
        <%= f.label :patient_name_cont, '患者名' %>
        <%= f.search_field :patient_name_cont, class: 'w-full px-3 py-2 border rounded', placeholder: '部分一致' %>
      </div>

      <div>
        <%= f.label :facility_id_eq, '施術場所' %>
        <%= f.collection_select :facility_id_eq, current_user.facilities.order(:name), :id, :name,
            { include_blank: 'すべて' },
            class: 'w-full px-3 py-2 border rounded' %>
      </div>

      <div>
        <%= f.label :treatment_date_gteq, '施術日（開始）' %>
        <%= f.date_field :treatment_date_gteq, class: 'w-full px-3 py-2 border rounded' %>
      </div>

      <div>
        <%= f.label :treatment_date_lteq, '施術日（終了）' %>
        <%= f.date_field :treatment_date_lteq, class: 'w-full px-3 py-2 border rounded' %>
      </div>
    </div>

    <div class="mt-4 flex space-x-2">
      <%= f.submit '検索', class: 'bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600' %>
      <%= link_to 'クリア', medical_records_path, class: 'px-4 py-2 border rounded hover:bg-gray-50' %>
    </div>
  <% end %>
</div>

<!-- 既存のテーブル -->
```

---

### 7.3 Day 16: E2Eテスト（System Spec）

#### 7.3.1 System Spec作成

```ruby
# spec/system/medical_records_spec.rb
require 'rails_helper'

RSpec.describe 'MedicalRecords', type: :system do
  let(:user) { create(:user) }
  let(:patient) { create(:patient, user: user, name: '田中花子') }
  let(:facility) { create(:facility, user: user, name: 'テストクリニック') }
  let!(:cost_sheet) { create(:cost_sheet, user: user, item_name: '眉毛アートメイク', standard_price: 50000) }

  before do
    sign_in user
  end

  describe 'カルテ作成フロー' do
    it 'カルテを作成できる' do
      visit new_medical_record_path

      select patient.name, from: '患者'
      select facility.name, from: '施術場所'
      fill_in '施術日', with: Date.today
      fill_in '施術内容', with: 'テスト施術内容'

      # コストシート選択
      within first('.nested-fields') do
        select cost_sheet.item_name, from: 'テンプレート'
        # 自動入力を確認
        expect(find('.item-name').value).to eq('眉毛アートメイク')
        expect(find('.unit-price').value).to eq('50000')
      end

      click_button '登録'

      expect(page).to have_content('カルテを作成しました')
      expect(page).to have_content(patient.name)
      expect(page).to have_content('¥50,000')
    end
  end

  describe '検索フロー' do
    let!(:record1) { create(:medical_record, user: user, patient: patient, facility: facility, treatment_date: Date.today) }

    it '患者名で検索できる' do
      visit medical_records_path

      fill_in '患者名', with: '田中'
      click_button '検索'

      expect(page).to have_content('田中花子')
    end
  end
end
```

```bash
bundle exec rspec spec/system/medical_records_spec.rb
```

---

## 8. トラブルシューティング

### 8.1 よくあるエラー

#### nested attributesが保存されない

**原因:** Strong Parametersの設定ミス

```ruby
# 正しい設定
def medical_record_params
  params.require(:medical_record).permit(
    :patient_id, :facility_id, :treatment_date,
    cost_items_attributes: [:id, :item_name, :unit_price, :quantity, :_destroy]
  )
end
```

#### Stimulusコントローラーが動かない

**原因:** importしていない

```js
// app/javascript/controllers/index.js
import CostItemsController from "./cost_items_controller"
application.register("cost-items", CostItemsController)
```

#### 画像アップロードでエラー

**原因:** Active Storageマイグレーション未実行

```bash
rails active_storage:install
rails db:migrate
```

---

## 9. 成功基準

### 9.1 Phase 3完了チェックリスト

#### 機能面
- [ ] コストシートCRUD動作
- [ ] カルテCRUD動作
- [ ] コスト項目の動的追加・削除
- [ ] 金額の自動計算
- [ ] 画像アップロード（最大5枚）
- [ ] タグ付け機能
- [ ] 検索・フィルタリング

#### テスト
- [ ] モデルスペック全て成功
- [ ] リクエストスペック全て成功
- [ ] システムスペック全て成功
- [ ] RuboCop 0違反

#### ブラウザ動作確認
- [ ] カルテ新規作成
- [ ] コストシート選択で自動入力
- [ ] コスト項目追加・削除
- [ ] 合計金額自動計算
- [ ] 画像アップロード・削除
- [ ] 検索機能

#### CI/CD
- [ ] GitHub Actions全てグリーン
- [ ] カバレッジ維持（80%以上）

---

## 10. 次のステップ（Phase 4）

Phase 3完了後は、Phase 4で以下を実装します:

- 売上管理ダッシュボード
- 請求書自動生成
- PDF出力機能
- 本番環境デプロイ

---

**Document Version**: 1.0  
**Last Updated**: 2025-10-13  
**Status**: Ready for Implementation

このガイドに従って、段階的にPhase 3を実装してください。各ステップでテストを実行し、ブラウザで動作確認することを忘れずに!

🚀 Phase 3の実装を始めましょう!
# 詳細設計書

**プロジェクト名**: フリーランスアートメイク施術者向け電子カルテアプリ
**作成日**: 2025-10-12
**バージョン**: 1.0
**言語**: 日本語

---

## 1. はじめに

### 1.1 本ドキュメントの目的

本書は、電子カルテアプリの詳細設計を記述し、実装の指針とするものです。

**対象読者:**
- 開発者（自分自身）
- コードレビュアー
- 将来のメンテナンス担当者

**記載内容:**
- 全モデルの詳細仕様
- 全コントローラーの詳細仕様
- ビジネスロジック詳細
- Stimulusコントローラー仕様
- サービスクラス設計

### 1.2 設計方針

- **Rails Way**: Railsの規約に従う
- **Fat Model, Thin Controller**: ビジネスロジックはモデルに集約
- **DRY原則**: 重複を避け、再利用可能なコードを書く
- **TDD**: テストファーストで実装
- **セキュリティファースト**: 患者情報を扱うため、セキュリティを最優先

---

## 2. モデル詳細設計

### 2.1 User（ユーザー）

施術者のアカウント情報を管理するモデル。

#### 2.1.1 属性

| カラム名 | 型 | 制約 | デフォルト | 説明 |
|---------|-----|------|-----------|------|
| id | bigint | PK | auto | 主キー |
| email | string | NOT NULL, UNIQUE | - | メールアドレス |
| encrypted_password | string | NOT NULL | - | 暗号化パスワード |
| reset_password_token | string | UNIQUE | NULL | パスワードリセットトークン |
| reset_password_sent_at | datetime | - | NULL | パスワードリセット送信日時 |
| remember_created_at | datetime | - | NULL | ログイン状態維持日時 |
| provider | string | - | NULL | OAuth プロバイダー |
| uid | string | - | NULL | OAuth UID |
| name | string | - | NULL | 施術者名 |
| created_at | datetime | NOT NULL | - | 作成日時 |
| updated_at | datetime | NOT NULL | - | 更新日時 |

#### 2.1.2 バリデーション

```ruby
# app/models/user.rb
class User < ApplicationRecord
  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  # Associations
  has_many :facilities, dependent: :destroy
  has_many :patients, dependent: :destroy
  has_many :medical_records, dependent: :destroy
  has_many :cost_sheets, dependent: :destroy
  has_many :invoices, dependent: :destroy
  has_many :tags, dependent: :destroy

  # Validations
  validates :email, presence: true, uniqueness: true
  validates :name, length: { maximum: 100 }, allow_blank: true

  # OmniAuth用メソッド
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.name = auth.info.name
    end
  end
end
```

#### 2.1.3 メソッド

| メソッド名 | 引数 | 戻り値 | 説明 |
|-----------|------|--------|------|
| `from_omniauth` | auth (OmniAuth情報) | User | OAuth認証からユーザーを作成/取得 |
| `display_name` | なし | String | 表示用の名前（name または email） |

```ruby
def display_name
  name.presence || email.split('@').first
end
```

---

### 2.2 Facility（施術場所）

クリニック・病院などの施術場所を管理するモデル。

#### 2.2.1 属性

| カラム名 | 型 | 制約 | デフォルト | 説明 |
|---------|-----|------|-----------|------|
| id | bigint | PK | auto | 主キー |
| user_id | bigint | FK, NOT NULL | - | 施術者ID |
| name | string | NOT NULL | - | 施術場所名 |
| address | text | - | NULL | 住所 |
| phone | string | - | NULL | 電話番号 |
| email | string | - | NULL | メールアドレス |
| notes | text | - | NULL | 備考 |
| created_at | datetime | NOT NULL | - | 作成日時 |
| updated_at | datetime | NOT NULL | - | 更新日時 |

#### 2.2.2 バリデーション

```ruby
# app/models/facility.rb
class Facility < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :medical_records, dependent: :restrict_with_error
  has_many :invoices, dependent: :restrict_with_error

  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :phone, format: { with: /\A\d{2,4}-?\d{2,4}-?\d{3,4}\z/, allow_blank: true }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_name, -> { order(:name) }
end
```

#### 2.2.3 メソッド

| メソッド名 | 引数 | 戻り値 | 説明 |
|-----------|------|--------|------|
| `has_records?` | なし | Boolean | 施術記録が存在するか |
| `total_revenue` | start_date, end_date | BigDecimal | 期間内の売上合計 |
| `medical_records_count` | なし | Integer | 施術記録数 |

```ruby
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
```

---

### 2.3 Patient（患者）

施術を受ける患者の情報を管理するモデル。

#### 2.3.1 属性

| カラム名 | 型 | 制約 | デフォルト | 説明 |
|---------|-----|------|-----------|------|
| id | bigint | PK | auto | 主キー |
| user_id | bigint | FK, NOT NULL | - | 施術者ID |
| name | string | NOT NULL | - | 患者名 |
| birth_date | date | - | NULL | 生年月日 |
| gender | integer | - | 0 | 性別（enum） |
| phone | string | - | NULL | 電話番号 |
| email | string | - | NULL | メールアドレス |
| allergy_info | text | - | NULL | アレルギー情報 |
| medical_history | text | - | NULL | 既往歴 |
| notes | text | - | NULL | 備考 |
| created_at | datetime | NOT NULL | - | 作成日時 |
| updated_at | datetime | NOT NULL | - | 更新日時 |

#### 2.3.2 バリデーション

```ruby
# app/models/patient.rb
class Patient < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :medical_records, dependent: :restrict_with_error
  has_many :facilities, through: :medical_records

  # Enums
  enum gender: { unspecified: 0, male: 1, female: 2, other: 3 }

  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :birth_date, comparison: { less_than_or_equal_to: -> { Date.today } }, allow_blank: true
  validates :phone, format: { with: /\A\d{2,4}-?\d{2,4}-?\d{3,4}\z/, allow_blank: true }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_name, -> { order(:name) }
  scope :search_by_name, ->(query) { where('name LIKE ?', "%#{sanitize_sql_like(query)}%") }
end
```

#### 2.3.3 メソッド

| メソッド名 | 引数 | 戻り値 | 説明 |
|-----------|------|--------|------|
| `age` | なし | Integer/nil | 年齢を計算 |
| `has_records?` | なし | Boolean | 施術記録が存在するか |
| `last_treatment_date` | なし | Date/nil | 最後の施術日 |
| `total_spent` | なし | BigDecimal | 累計支払額 |

```ruby
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
```

---

### 2.4 MedicalRecord（カルテ）

施術記録を管理するモデル。アプリの中心的なエンティティ。

#### 2.4.1 属性

| カラム名 | 型 | 制約 | デフォルト | 説明 |
|---------|-----|------|-----------|------|
| id | bigint | PK | auto | 主キー |
| user_id | bigint | FK, NOT NULL | - | 施術者ID |
| patient_id | bigint | FK, NOT NULL | - | 患者ID |
| facility_id | bigint | FK, NOT NULL | - | 施術場所ID |
| invoice_id | bigint | FK | NULL | 請求書ID |
| treatment_date | date | NOT NULL | - | 施術日 |
| treatment_content | text | - | NULL | 施術内容 |
| counseling_content | text | - | NULL | カウンセリング内容 |
| total_amount | decimal(10,2) | NOT NULL | 0.00 | 合計金額 |
| created_at | datetime | NOT NULL | - | 作成日時 |
| updated_at | datetime | NOT NULL | - | 更新日時 |

#### 2.4.2 バリデーション

```ruby
# app/models/medical_record.rb
class MedicalRecord < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :patient
  belongs_to :facility
  belongs_to :invoice, optional: true

  has_many :cost_items, dependent: :destroy
  has_many :medical_record_tags, dependent: :destroy
  has_many :tags, through: :medical_record_tags

  has_many_attached :photos

  # Nested attributes
  accepts_nested_attributes_for :cost_items, allow_destroy: true, reject_if: :all_blank

  # Validations
  validates :treatment_date, presence: true
  validates :treatment_date, comparison: { less_than_or_equal_to: -> { Date.today } }
  validates :total_amount, numericality: { greater_than_or_equal_to: 0 }
  validate :photos_count_limit
  validate :photos_size_limit

  # Callbacks
  after_save :update_total_amount
  before_destroy :check_invoice_association

  # Scopes
  scope :recent, -> { order(treatment_date: :desc, created_at: :desc) }
  scope :by_date, -> { order(:treatment_date) }
  scope :in_period, ->(start_date, end_date) { where(treatment_date: start_date..end_date) }
  scope :by_facility, ->(facility_id) { where(facility_id: facility_id) }
  scope :by_patient, ->(patient_id) { where(patient_id: patient_id) }
  scope :unbilled, -> { where(invoice_id: nil) }
  scope :billed, -> { where.not(invoice_id: nil) }

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

#### 2.4.3 メソッド

| メソッド名 | 引数 | 戻り値 | 説明 |
|-----------|------|--------|------|
| `can_destroy?` | なし | Boolean | 削除可能か判定 |
| `add_tag` | tag_name | Tag | タグを追加 |
| `remove_tag` | tag | Boolean | タグを削除 |
| `thumbnail` | なし | Variant | サムネイル画像 |

```ruby
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
```

---

### 2.5 CostSheet（コストシートテンプレート）

施術や薬剤の料金テンプレートを管理するモデル。

#### 2.5.1 属性

| カラム名 | 型 | 制約 | デフォルト | 説明 |
|---------|-----|------|-----------|------|
| id | bigint | PK | auto | 主キー |
| user_id | bigint | FK, NOT NULL | - | 施術者ID |
| item_name | string | NOT NULL | - | 項目名 |
| standard_price | decimal(10,2) | NOT NULL | 0.00 | 標準価格 |
| category | string | - | NULL | カテゴリ |
| description | text | - | NULL | 説明文 |
| created_at | datetime | NOT NULL | - | 作成日時 |
| updated_at | datetime | NOT NULL | - | 更新日時 |

#### 2.5.2 バリデーション

```ruby
# app/models/cost_sheet.rb
class CostSheet < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :cost_items

  # Validations
  validates :item_name, presence: true, length: { maximum: 100 }
  validates :standard_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :category, inclusion: { in: %w[treatment medicine supplies other], allow_blank: true }

  # Scopes
  scope :by_category, ->(category) { where(category: category) }
  scope :by_name, -> { order(:item_name) }
  scope :recent, -> { order(created_at: :desc) }
end
```

#### 2.5.3 カテゴリ定義

```ruby
CATEGORIES = {
  'treatment' => '施術',
  'medicine' => '薬剤',
  'supplies' => '消耗品',
  'other' => 'その他'
}.freeze

def category_name
  CATEGORIES[category] || category
end
```

---

### 2.6 CostItem（コスト項目）

カルテごとの実際のコスト項目を管理するモデル。

#### 2.6.1 属性

| カラム名 | 型 | 制約 | デフォルト | 説明 |
|---------|-----|------|-----------|------|
| id | bigint | PK | auto | 主キー |
| medical_record_id | bigint | FK, NOT NULL | - | カルテID |
| cost_sheet_id | bigint | FK | NULL | コストシートID（参照元） |
| item_name | string | NOT NULL | - | 項目名 |
| unit_price | decimal(10,2) | NOT NULL | 0.00 | 単価 |
| quantity | integer | NOT NULL | 1 | 数量 |
| subtotal | decimal(10,2) | NOT NULL | 0.00 | 小計 |
| notes | text | - | NULL | 備考 |
| created_at | datetime | NOT NULL | - | 作成日時 |
| updated_at | datetime | NOT NULL | - | 更新日時 |

#### 2.6.2 バリデーション

```ruby
# app/models/cost_item.rb
class CostItem < ApplicationRecord
  # Associations
  belongs_to :medical_record
  belongs_to :cost_sheet, optional: true

  # Validations
  validates :item_name, presence: true
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :subtotal, numericality: { greater_than_or_equal_to: 0 }

  # Callbacks
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

### 2.7 Invoice（請求書）

施術場所ごとの請求書を管理するモデル。

#### 2.7.1 属性

| カラム名 | 型 | 制約 | デフォルト | 説明 |
|---------|-----|------|-----------|------|
| id | bigint | PK | auto | 主キー |
| user_id | bigint | FK, NOT NULL | - | 施術者ID |
| facility_id | bigint | FK, NOT NULL | - | 施術場所ID |
| invoice_number | string | NOT NULL, UNIQUE | - | 請求書番号 |
| issue_date | date | NOT NULL | - | 発行日 |
| billing_period_start | date | NOT NULL | - | 請求期間（開始） |
| billing_period_end | date | NOT NULL | - | 請求期間（終了） |
| total_amount | decimal(10,2) | NOT NULL | 0.00 | 合計金額 |
| status | integer | NOT NULL | 0 | ステータス（enum） |
| sent_at | datetime | - | NULL | 送付日時 |
| notes | text | - | NULL | 備考 |
| created_at | datetime | NOT NULL | - | 作成日時 |
| updated_at | datetime | NOT NULL | - | 更新日時 |

#### 2.7.2 バリデーション

```ruby
# app/models/invoice.rb
class Invoice < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :facility
  has_many :medical_records

  # Enums
  enum status: { draft: 0, issued: 1, sent: 2, paid: 3, cancelled: 4 }

  # Validations
  validates :invoice_number, presence: true, uniqueness: true
  validates :issue_date, presence: true
  validates :billing_period_start, presence: true
  validates :billing_period_end, presence: true
  validates :billing_period_end, comparison: { greater_than_or_equal_to: :billing_period_start }
  validates :total_amount, numericality: { greater_than_or_equal_to: 0 }

  # Callbacks
  before_create :generate_invoice_number
  before_save :calculate_total_amount

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_date, -> { order(issue_date: :desc) }
  scope :by_status, ->(status) { where(status: status) }
  scope :in_period, ->(start_date, end_date) { where('issue_date >= ? AND issue_date <= ?', start_date, end_date) }

  private

  def generate_invoice_number
    date_prefix = issue_date.strftime('%Y%m')
    last_invoice = Invoice.where('invoice_number LIKE ?', "INV-#{date_prefix}-%").order(:invoice_number).last

    if last_invoice
      last_number = last_invoice.invoice_number.split('-').last.to_i
      new_number = last_number + 1
    else
      new_number = 1
    end

    self.invoice_number = "INV-#{date_prefix}-#{new_number.to_s.rjust(4, '0')}"
  end

  def calculate_total_amount
    self.total_amount = medical_records.sum(:total_amount)
  end
end
```

#### 2.7.3 メソッド

| メソッド名 | 引数 | 戻り値 | 説明 |
|-----------|------|--------|------|
| `can_edit?` | なし | Boolean | 編集可能か判定 |
| `can_cancel?` | なし | Boolean | キャンセル可能か判定 |
| `mark_as_sent!` | なし | Boolean | 送付済みにする |
| `mark_as_paid!` | なし | Boolean | 支払済みにする |

```ruby
def can_edit?
  draft? || issued?
end

def can_cancel?
  !paid?
end

def mark_as_sent!
  update(status: :sent, sent_at: Time.current)
end

def mark_as_paid!
  update(status: :paid)
end
```

---

### 2.8 Tag（タグ）

カルテの分類用タグを管理するモデル。

#### 2.8.1 属性

| カラム名 | 型 | 制約 | デフォルト | 説明 |
|---------|-----|------|-----------|------|
| id | bigint | PK | auto | 主キー |
| user_id | bigint | FK, NOT NULL | - | 施術者ID |
| name | string | NOT NULL | - | タグ名 |
| category | string | - | 'custom' | カテゴリ |
| color | string | - | '#3B82F6' | 表示色（Hex） |
| created_at | datetime | NOT NULL | - | 作成日時 |
| updated_at | datetime | NOT NULL | - | 更新日時 |

#### 2.8.2 バリデーション

```ruby
# app/models/tag.rb
class Tag < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :medical_record_tags, dependent: :destroy
  has_many :medical_records, through: :medical_record_tags

  # Validations
  validates :name, presence: true, length: { maximum: 50 }
  validates :name, uniqueness: { scope: :user_id }
  validates :color, format: { with: /\A#[0-9A-F]{6}\z/i, allow_blank: true }

  # Scopes
  scope :by_category, ->(category) { where(category: category) }
  scope :by_name, -> { order(:name) }
  scope :custom_tags, -> { where(category: 'custom') }
end
```

---

## 3. コントローラー詳細設計

### 3.1 ApplicationController

全コントローラーの基底クラス。

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  # エラーハンドリング
  rescue_from ActiveRecord::RecordNotFound, with: :render_404
  rescue_from ActionController::ParameterMissing, with: :render_400

  private

  def render_404
    render file: Rails.public_path.join('404.html'), status: :not_found, layout: false
  end

  def render_400
    render file: Rails.public_path.join('400.html'), status: :bad_request, layout: false
  end
end
```

---

### 3.2 DashboardController

ダッシュボード画面を管理するコントローラー。

#### 3.2.1 アクション一覧

| アクション | HTTPメソッド | URL | 説明 |
|-----------|------------|-----|------|
| index | GET | /dashboard | ダッシュボード表示 |

#### 3.2.2 実装

```ruby
# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  def index
    @recent_records = current_user.medical_records.recent.limit(5).includes(:patient, :facility)
    @total_revenue_this_month = calculate_monthly_revenue(Date.today)
    @total_revenue_last_month = calculate_monthly_revenue(Date.today.last_month)
    @total_patients = current_user.patients.count
    @total_facilities = current_user.facilities.count
  end

  private

  def calculate_monthly_revenue(date)
    start_date = date.beginning_of_month
    end_date = date.end_of_month
    current_user.medical_records.in_period(start_date, end_date).sum(:total_amount)
  end
end
```

---

### 3.3 FacilitiesController

施術場所のCRUDを管理するコントローラー。

#### 3.3.1 アクション一覧

| アクション | HTTPメソッド | URL | 説明 |
|-----------|------------|-----|------|
| index | GET | /facilities | 一覧表示 |
| show | GET | /facilities/:id | 詳細表示 |
| new | GET | /facilities/new | 新規作成フォーム |
| create | POST | /facilities | 新規作成処理 |
| edit | GET | /facilities/:id/edit | 編集フォーム |
| update | PATCH/PUT | /facilities/:id | 更新処理 |
| destroy | DELETE | /facilities/:id | 削除処理 |

#### 3.3.2 実装

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

---

### 3.4 PatientsController

患者のCRUDを管理するコントローラー。

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

---

### 3.5 MedicalRecordsController

カルテのCRUDを管理するコントローラー。最も重要なコントローラー。

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
    @cost_sheets = current_user.cost_sheets.by_category
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

---

### 3.6 CostSheetsController

コストシートのCRUDを管理するコントローラー。

```ruby
# app/controllers/cost_sheets_controller.rb
class CostSheetsController < ApplicationController
  before_action :set_cost_sheet, only: [:show, :edit, :update, :destroy]

  def index
    @cost_sheets = current_user.cost_sheets.by_name.page(params[:page])
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
    redirect_to cost_sheets_url, notice: 'コストシートを削除しました'
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

---

### 3.7 InvoicesController

請求書のCRUDと生成を管理するコントローラー。

```ruby
# app/controllers/invoices_controller.rb
class InvoicesController < ApplicationController
  before_action :set_invoice, only: [:show, :edit, :update, :destroy, :send_invoice, :mark_as_paid, :download_pdf]

  def index
    @invoices = current_user.invoices.recent.includes(:facility).page(params[:page])
  end

  def show
    @medical_records = @invoice.medical_records.includes(:patient)
  end

  def new
    @facilities = current_user.facilities.by_name
  end

  def create
    service = InvoiceGenerationService.new(current_user, invoice_params)
    result = service.call

    if result.success?
      redirect_to result.invoice, notice: '請求書を生成しました'
    else
      @facilities = current_user.facilities.by_name
      flash.now[:alert] = result.error
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @invoice.can_edit? && @invoice.update(invoice_params)
      redirect_to @invoice, notice: '請求書を更新しました'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @invoice.can_cancel?
      @invoice.update(status: :cancelled)
      redirect_to invoices_url, notice: '請求書をキャンセルしました'
    else
      redirect_to @invoice, alert: 'この請求書はキャンセルできません'
    end
  end

  def send_invoice
    @invoice.mark_as_sent!
    redirect_to @invoice, notice: '請求書を送付済みにしました'
  end

  def mark_as_paid
    @invoice.mark_as_paid!
    redirect_to @invoice, notice: '請求書を支払済みにしました'
  end

  def download_pdf
    pdf = InvoicePdfGenerator.new(@invoice).generate
    send_data pdf, filename: "#{@invoice.invoice_number}.pdf", type: 'application/pdf', disposition: 'attachment'
  end

  private

  def set_invoice
    @invoice = current_user.invoices.find(params[:id])
  end

  def invoice_params
    params.require(:invoice).permit(:facility_id, :year, :month, :notes)
  end
end
```

---

## 4. サービスクラス設計

### 4.1 InvoiceGenerationService

請求書生成のビジネスロジックを担当するサービスクラス。

```ruby
# app/services/invoice_generation_service.rb
class InvoiceGenerationService
  attr_reader :user, :params, :error

  def initialize(user, params)
    @user = user
    @params = params
    @error = nil
  end

  def call
    facility = user.facilities.find(params[:facility_id])
    year = params[:year].to_i
    month = params[:month].to_i

    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month

    records = facility.medical_records
                     .where(treatment_date: start_date..end_date)
                     .where(invoice_id: nil)

    if records.empty?
      @error = '指定期間に請求対象の施術記録がありません'
      return self
    end

    invoice = Invoice.new(
      user: user,
      facility: facility,
      issue_date: Date.today,
      billing_period_start: start_date,
      billing_period_end: end_date,
      status: :draft,
      notes: params[:notes]
    )

    ActiveRecord::Base.transaction do
      invoice.save!
      records.update_all(invoice_id: invoice.id)
    end

    OpenStruct.new(success?: true, invoice: invoice)
  rescue => e
    @error = e.message
    OpenStruct.new(success?: false, error: @error)
  end
end
```

---

### 4.2 InvoicePdfGenerator

請求書PDFを生成するサービスクラス。

```ruby
# app/services/invoice_pdf_generator.rb
class InvoicePdfGenerator
  def initialize(invoice)
    @invoice = invoice
    @pdf = Prawn::Document.new
  end

  def generate
    setup_fonts
    render_header
    render_billing_info
    render_table
    render_footer
    @pdf.render
  end

  private

  def setup_fonts
    font_path = Rails.root.join('app', 'assets', 'fonts', 'ipaexg.ttf')
    @pdf.font_families.update('IPAexGothic' => { normal: font_path })
    @pdf.font 'IPAexGothic'
  end

  def render_header
    @pdf.text '請求書', size: 24, align: :center, style: :bold
    @pdf.move_down 20
    @pdf.text "請求書番号: #{@invoice.invoice_number}", size: 12
    @pdf.text "発行日: #{@invoice.issue_date}", size: 12
    @pdf.move_down 30
  end

  def render_billing_info
    @pdf.text "請求先: #{@invoice.facility.name}", size: 14, style: :bold
    @pdf.text "期間: #{@invoice.billing_period_start} 〜 #{@invoice.billing_period_end}"
    @pdf.move_down 20
  end

  def render_table
    table_data = [['日付', '患者名', '施術内容', '金額']]

    @invoice.medical_records.each do |record|
      table_data << [
        record.treatment_date.to_s,
        record.patient.name,
        record.treatment_content.to_s.truncate(30),
        "¥#{record.total_amount.to_i.to_s(:delimited)}"
      ]
    end

    table_data << ['', '', '合計', "¥#{@invoice.total_amount.to_i.to_s(:delimited)}"]

    @pdf.table(table_data, header: true, width: @pdf.bounds.width) do
      row(0).font_style = :bold
      row(-1).font_style = :bold
      columns(3).align = :right
    end
  end

  def render_footer
    @pdf.move_down 30
    @pdf.text '振込先: 〇〇銀行 △△支店 普通 1234567', size: 10
    @pdf.text "お振込期限: #{(@invoice.issue_date + 30.days)}", size: 10
  end
end
```

---

## 5. Stimulusコントローラー設計

### 5.1 cost-items_controller

コスト項目の動的追加・削除を管理するStimulusコントローラー。

```javascript
// app/javascript/controllers/cost_items_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template", "total", "addButton"]
  static values = {
    costSheets: Array,
    maxItems: { type: Number, default: 10 }
  }

  connect() {
    this.updateTotal()
    this.updateAddButtonState()
  }

  addItem(event) {
    event.preventDefault()

    if (this.itemCount >= this.maxItemsValue) {
      alert(`コスト項目は最大${this.maxItemsValue}件までです`)
      return
    }

    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.containerTarget.insertAdjacentHTML('beforeend', content)
    this.updateAddButtonState()
  }

  removeItem(event) {
    event.preventDefault()
    const item = event.target.closest('.cost-item')

    if (this.itemCount <= 1) {
      alert('最低1つのコスト項目が必要です')
      return
    }

    const destroyInput = item.querySelector('input[name*="_destroy"]')
    if (destroyInput) {
      destroyInput.value = '1'
      item.style.display = 'none'
    } else {
      item.remove()
    }

    this.calculateTotal()
    this.updateAddButtonState()
  }

  selectCostSheet(event) {
    const select = event.target
    const costSheetId = select.value

    if (!costSheetId) return

    const costSheet = this.costSheetsValue.find(cs => cs.id == costSheetId)
    if (!costSheet) return

    const item = select.closest('.cost-item')
    const nameInput = item.querySelector('.item-name')
    const priceInput = item.querySelector('.unit-price')

    if (nameInput) nameInput.value = costSheet.item_name
    if (priceInput) priceInput.value = costSheet.standard_price

    this.calculateTotal()
  }

  calculateTotal() {
    let total = 0

    this.containerTarget.querySelectorAll('.cost-item:not([style*="display: none"])').forEach(item => {
      const price = parseFloat(item.querySelector('.unit-price').value) || 0
      const qty = parseInt(item.querySelector('.quantity').value) || 1
      const subtotal = price * qty

      const subtotalDisplay = item.querySelector('.subtotal-display')
      if (subtotalDisplay) {
        subtotalDisplay.textContent = `¥${subtotal.toLocaleString()}`
      }

      total += subtotal
    })

    this.totalTarget.textContent = `¥${total.toLocaleString()}`
  }

  updateTotal(event) {
    this.calculateTotal()
  }

  get itemCount() {
    return this.containerTarget.querySelectorAll('.cost-item:not([style*="display: none"])').length
  }

  updateAddButtonState() {
    if (this.hasAddButtonTarget) {
      this.addButtonTarget.disabled = this.itemCount >= this.maxItemsValue
    }
  }
}
```

---

### 5.2 image-preview_controller

画像プレビューを管理するStimulusコントローラー。

```javascript
// app/javascript/controllers/image_preview_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "container"]
  static values = {
    maxFiles: { type: Number, default: 5 },
    maxSize: { type: Number, default: 10485760 } // 10MB
  }

  preview(event) {
    const files = Array.from(event.target.files)

    // ファイル数チェック
    const currentFiles = this.previewTargets.length
    if (currentFiles + files.length > this.maxFilesValue) {
      alert(`画像は最大${this.maxFilesValue}枚までアップロードできます`)
      this.inputTarget.value = ''
      return
    }

    // ファイルサイズチェック
    for (const file of files) {
      if (file.size > this.maxSizeValue) {
        alert(`${file.name}のサイズが10MBを超えています`)
        this.inputTarget.value = ''
        return
      }
    }

    // プレビュー表示
    files.forEach(file => {
      const reader = new FileReader()
      reader.onload = (e) => {
        const html = `
          <div class="image-preview-item" data-image-preview-target="preview">
            <img src="${e.target.result}" alt="プレビュー" />
            <button type="button" class="remove-button" data-action="click->image-preview#remove">
              ×
            </button>
          </div>
        `
        this.containerTarget.insertAdjacentHTML('beforeend', html)
      }
      reader.readAsDataURL(file)
    })
  }

  remove(event) {
    event.preventDefault()
    const previewItem = event.target.closest('.image-preview-item')
    previewItem.remove()

    // ファイル入力をリセット（再選択可能にする）
    this.inputTarget.value = ''
  }
}
```

---

## 6. ルーティング設計

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Devise
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  # Root
  root 'dashboard#index'

  # Dashboard
  get 'dashboard', to: 'dashboard#index'

  # Resources
  resources :facilities
  resources :patients
  resources :cost_sheets

  resources :medical_records do
    member do
      delete :remove_photo
    end
  end

  resources :invoices do
    member do
      post :send_invoice
      post :mark_as_paid
      get :download_pdf
    end
  end

  resources :tags, only: [:index, :create, :destroy]

  # Statistics
  namespace :statistics do
    get 'revenue', to: 'revenue#index'
  end
end
```

---

## 7. バリデーションメッセージ日本語化

```yaml
# config/locales/ja.yml
ja:
  activerecord:
    models:
      user: ユーザー
      facility: 施術場所
      patient: 患者
      medical_record: カルテ
      cost_sheet: コストシート
      cost_item: コスト項目
      invoice: 請求書
      tag: タグ
    attributes:
      user:
        email: メールアドレス
        password: パスワード
        name: 名前
      facility:
        name: 施術場所名
        address: 住所
        phone: 電話番号
        email: メールアドレス
      patient:
        name: 患者名
        birth_date: 生年月日
        gender: 性別
        phone: 電話番号
        email: メールアドレス
        allergy_info: アレルギー情報
        medical_history: 既往歴
      medical_record:
        patient: 患者
        facility: 施術場所
        treatment_date: 施術日
        treatment_content: 施術内容
        counseling_content: カウンセリング内容
        total_amount: 合計金額
        photos: 写真
      cost_sheet:
        item_name: 項目名
        standard_price: 標準価格
        category: カテゴリ
      invoice:
        facility: 施術場所
        invoice_number: 請求書番号
        issue_date: 発行日
        billing_period_start: 請求期間（開始）
        billing_period_end: 請求期間（終了）
        total_amount: 合計金額
        status: ステータス
    errors:
      messages:
        record_invalid: 'バリデーションに失敗しました: %{errors}'
        restrict_dependent_destroy:
          has_many: '%{record}が存在しているので削除できません'
```

---

## 8. エラーハンドリング設計

### 8.1 カスタムエラーページ

```ruby
# config/application.rb
config.exceptions_app = self.routes

# config/routes.rb
match '/404', to: 'errors#not_found', via: :all
match '/422', to: 'errors#unprocessable_entity', via: :all
match '/500', to: 'errors#internal_server_error', via: :all
```

```ruby
# app/controllers/errors_controller.rb
class ErrorsController < ApplicationController
  skip_before_action :authenticate_user!

  def not_found
    render status: 404
  end

  def unprocessable_entity
    render status: 422
  end

  def internal_server_error
    render status: 500
  end
end
```

---

## 9. セキュリティ対策

### 9.1 Strong Parameters

全コントローラーでStrong Parametersを使用し、マスアサインメント攻撃を防ぐ。

### 9.2 CSRF対策

```ruby
# app/controllers/application_controller.rb
protect_from_forgery with: :exception
```

### 9.3 認可チェック

```ruby
# 必ず current_user 経由でデータを取得
@facility = current_user.facilities.find(params[:id])
```

### 9.4 SQL インジェクション対策

```ruby
# ✅ Good: プレースホルダー使用
Patient.where('name LIKE ?', "%#{params[:query]}%")

# ❌ Bad: 文字列連結
Patient.where("name LIKE '%#{params[:query]}%'")
```

---

## 10. パフォーマンス最適化

### 10.1 N+1クエリ対策

```ruby
# ✅ Good: includes使用
@medical_records = current_user.medical_records
                                .includes(:patient, :facility, :tags)
                                .recent

# ❌ Bad: includesなし
@medical_records = current_user.medical_records.recent
```

### 10.2 ページネーション

全一覧画面でKaminariを使用。

```ruby
@patients = current_user.patients.page(params[:page]).per(20)
```

### 10.3 データベースインデックス

頻繁に検索されるカラムにインデックスを追加。

```ruby
add_index :medical_records, [:user_id, :treatment_date]
add_index :medical_records, [:facility_id, :treatment_date]
add_index :patients, [:user_id, :name]
```

---

## 11. テスト設計方針

### 11.1 テストレベルと責務

- **Model Spec**: ビジネスロジック、バリデーション、スコープ
- **Request Spec**: HTTPリクエスト、レスポンス、認可
- **System Spec**: E2E、JavaScript込みの動作確認

### 11.2 FactoryBot設計

```ruby
# spec/factories/medical_records.rb
FactoryBot.define do
  factory :medical_record do
    user
    patient
    facility
    treatment_date { Date.today }
    treatment_content { 'アートメイク施術' }
    total_amount { 50000 }

    trait :with_cost_items do
      after(:create) do |record|
        create_list(:cost_item, 2, medical_record: record)
      end
    end

    trait :with_photos do
      after(:create) do |record|
        record.photos.attach(
          io: File.open(Rails.root.join('spec/fixtures/files/sample_image.jpg')),
          filename: 'sample_image.jpg',
          content_type: 'image/jpeg'
        )
      end
    end
  end
end
```

---

**Document Version**: 1.0
**Last Updated**: 2025-10-12
**Next Review**: Phase 1 実装開始時

---

## 付録: 実装チェックリスト

### Phase 1

- [ ] User モデル（Devise）
- [ ] Facility モデル + CRUD
- [ ] Patient モデル + CRUD
- [ ] CostSheet モデル + CRUD
- [ ] MedicalRecord モデル + CRUD
- [ ] CostItem モデル（nested attributes）
- [ ] Stimulus コントローラー（cost-items, image-preview）
- [ ] 検索・フィルタリング機能
- [ ] Tag機能

### Phase 2

- [ ] Invoice モデル + CRUD
- [ ] InvoiceGenerationService
- [ ] InvoicePdfGenerator
- [ ] 売上ダッシュボード
- [ ] 月次集計機能
- [ ] CSV エクスポート

### Phase 3

- [ ] UI/UX 改善
- [ ] パフォーマンス最適化
- [ ] セキュリティ強化
- [ ] エラーハンドリング強化

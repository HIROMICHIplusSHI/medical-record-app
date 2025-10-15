# Phase 5-B: 請求書生成機能 - 実装計画書

**作成日**: 2025-10-15
**対象期間**: Week 3-4 (2 週間)
**目標**: 施術場所ごとに月次請求書を自動生成し、PDF 出力できるようにする

---

## 📋 実装概要

### 解決する課題

フリーランス美容施術者が施術場所に対して請求書を発行する際の課題を解決:

- **手動集計の手間**: カルテから手動で請求書を作成 → 自動集計で効率化
- **請求漏れ**: カルテから請求書への転記ミス → システムで防止
- **PDF 作成の手間**: Word/Excel で手動作成 → ワンクリックで PDF 生成
- **請求履歴管理**: 紙/PDF ファイルで分散管理 → システムで一元管理

### 成果物

1. **Invoice モデル**: 請求書データの管理
2. **InvoiceItem モデル**: 請求書明細の管理
3. **請求書生成サービス**: カルテから自動集計
4. **PDF 生成サービス**: 日本語対応の PDF 出力
5. **請求書 CRUD 画面**: 一覧・詳細・作成・PDF 生成
6. **包括的なテスト**: Model/Request/System Spec

---

## 🎯 機能要件

### 1. 請求書管理機能

#### 1.1 請求書作成

- 施術場所と請求期間を指定してカルテを自動集計
- 請求書番号の自動採番（`INV-YYYYMM-XXXX`形式）
- 合計金額の自動計算
- ステータス管理（下書き・発行済み・送付済み・入金済み・キャンセル）

#### 1.2 請求書一覧

- 請求書の一覧表示（ページネーション付き）
- 施術場所・期間・ステータスでの検索（Ransack）
- 発行日順でソート

#### 1.3 請求書詳細

- 請求書情報の表示
- 含まれるカルテ明細の表示
- PDF 生成ボタン
- ステータス変更機能

#### 1.4 PDF 出力

- 日本語フォント対応（IPAex ゴシック）
- 請求書番号・発行日・請求期間の表示
- 施術場所情報の表示
- 明細テーブル（日付・患者名・施術内容・金額）
- 合計金額の表示
- 振込先情報の表示

---

## 🏗️ データモデル設計

### 1. Invoice モデル

```ruby
class Invoice < ApplicationRecord
  # リレーション
  belongs_to :user
  belongs_to :facility
  has_many :invoice_items, dependent: :destroy
  has_many :medical_records, through: :invoice_items
  has_one_attached :pdf_file

  # enum
  enum :status, {
    draft: 0,       # 下書き
    issued: 1,      # 発行済み
    sent: 2,        # 送付済み
    paid: 3,        # 入金済み
    cancelled: 9    # キャンセル
  }

  # バリデーション
  validates :invoice_number, presence: true, uniqueness: true
  validates :billing_period_start, :billing_period_end, presence: true
  validates :total_amount, numericality: { greater_than_or_equal_to: 0 }
  validate :end_date_after_start_date

  # コールバック
  before_validation :generate_invoice_number, on: :create
  before_save :calculate_total_amount

  # スコープ
  scope :recent, -> { order(issued_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }

  # Ransack設定
  def self.ransackable_attributes(_auth_object = nil)
    %w[invoice_number billing_period_start billing_period_end
       total_amount status issued_at created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[facility]
  end

  # インスタンスメソッド
  def period
    "#{billing_period_start.strftime('%Y/%m/%d')} 〜 #{billing_period_end.strftime('%Y/%m/%d')}"
  end

  def pdf_generated?
    pdf_file.attached?
  end

  private

  def generate_invoice_number
    return if invoice_number.present?

    year_month = billing_period_end.strftime('%Y%m')
    last_invoice = Invoice.where('invoice_number LIKE ?', "INV-#{year_month}-%")
                          .order(:invoice_number).last

    sequence = last_invoice ? last_invoice.invoice_number.split('-').last.to_i + 1 : 1
    self.invoice_number = "INV-#{year_month}-#{sequence.to_s.rjust(4, '0')}"
  end

  def calculate_total_amount
    self.total_amount = invoice_items.sum(&:amount)
  end

  def end_date_after_start_date
    return if billing_period_end.blank? || billing_period_start.blank?

    if billing_period_end < billing_period_start
      errors.add(:billing_period_end, 'は開始日以降の日付を指定してください')
    end
  end
end
```

### 2. InvoiceItem モデル

```ruby
class InvoiceItem < ApplicationRecord
  # リレーション
  belongs_to :invoice
  belongs_to :medical_record

  # バリデーション
  validates :description, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }

  # コールバック
  after_save :update_invoice_total
  after_destroy :update_invoice_total

  private

  def update_invoice_total
    invoice.save
  end
end
```

### 3. マイグレーション

#### invoices テーブル

```ruby
class CreateInvoices < ActiveRecord::Migration[7.2]
  def change
    create_table :invoices do |t|
      t.references :user, null: false, foreign_key: true
      t.references :facility, null: false, foreign_key: true
      t.string :invoice_number, null: false
      t.datetime :issued_at, null: false
      t.date :billing_period_start, null: false
      t.date :billing_period_end, null: false
      t.decimal :total_amount, precision: 10, scale: 2, default: 0.0, null: false
      t.integer :status, default: 0, null: false
      t.datetime :sent_at
      t.text :notes

      t.timestamps
    end

    add_index :invoices, :invoice_number, unique: true
    add_index :invoices, :user_id
    add_index :invoices, :facility_id
    add_index :invoices, [:facility_id, :billing_period_start]
    add_index :invoices, :status
  end
end
```

#### invoice_items テーブル

```ruby
class CreateInvoiceItems < ActiveRecord::Migration[7.2]
  def change
    create_table :invoice_items do |t|
      t.references :invoice, null: false, foreign_key: true
      t.references :medical_record, null: false, foreign_key: true
      t.string :description, null: false
      t.decimal :amount, precision: 10, scale: 2, default: 0.0, null: false

      t.timestamps
    end

    add_index :invoice_items, :invoice_id
    add_index :invoice_items, :medical_record_id
    add_index :invoice_items, [:invoice_id, :medical_record_id], unique: true
  end
end
```

---

## 🔧 サービスクラス設計

### 1. InvoiceGenerator

請求書を自動生成するサービスクラス。

```ruby
# app/services/invoice_generator.rb
class InvoiceGenerator
  def initialize(user:, facility:, start_date:, end_date:)
    @user = user
    @facility = facility
    @start_date = start_date
    @end_date = end_date
  end

  def generate
    validate_params!

    Invoice.transaction do
      invoice = create_invoice
      add_invoice_items(invoice)
      invoice.save!
      invoice
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Invoice generation failed: #{e.message}")
    raise
  end

  private

  def validate_params!
    raise ArgumentError, '施術場所が見つかりません' if @facility.nil?
    raise ArgumentError, '請求期間を指定してください' if @start_date.nil? || @end_date.nil?
    raise ArgumentError, '終了日は開始日以降を指定してください' if @end_date < @start_date
  end

  def create_invoice
    Invoice.new(
      user: @user,
      facility: @facility,
      billing_period_start: @start_date,
      billing_period_end: @end_date,
      issued_at: Time.current,
      status: :draft
    )
  end

  def add_invoice_items(invoice)
    medical_records.find_each do |record|
      invoice.invoice_items.build(
        medical_record: record,
        description: format_description(record),
        amount: record.total_cost
      )
    end
  end

  def medical_records
    @medical_records ||= MedicalRecord
      .where(facility: @facility, user: @user)
      .where(visit_date: @start_date..@end_date)
      .includes(:patient, :cost_items)
      .order(visit_date: :asc)
  end

  def format_description(record)
    "#{record.visit_date.strftime('%Y/%m/%d')} - #{record.patient.name} - #{truncate_content(record.chief_complaint)}"
  end

  def truncate_content(text)
    text.to_s.truncate(30, omission: '...')
  end
end
```

### 2. InvoicePdfGenerator

PDF 生成を担当するサービスクラス。

```ruby
# app/services/invoice_pdf_generator.rb
class InvoicePdfGenerator
  FONT_PATH = Rails.root.join('app', 'assets', 'fonts', 'ipaexg.ttf')

  def initialize(invoice)
    @invoice = invoice
    @pdf = Prawn::Document.new(page_size: 'A4', margin: 40)
  end

  def generate
    setup_fonts
    render_header
    render_invoice_info
    render_billing_info
    render_items_table
    render_total
    render_footer
    @pdf.render
  end

  private

  def setup_fonts
    @pdf.font_families.update('IPAexGothic' => { normal: FONT_PATH.to_s })
    @pdf.font 'IPAexGothic'
  end

  def render_header
    @pdf.text '請求書', size: 24, align: :center, style: :bold
    @pdf.move_down 30
  end

  def render_invoice_info
    @pdf.text "請求書番号: #{@invoice.invoice_number}", size: 12
    @pdf.text "発行日: #{@invoice.issued_at.strftime('%Y年%m月%d日')}", size: 12
    @pdf.move_down 20
  end

  def render_billing_info
    @pdf.text "#{@invoice.facility.name} 様", size: 14, style: :bold
    @pdf.move_down 5
    @pdf.text "請求期間: #{@invoice.period}", size: 10
    @pdf.text "発行者: #{@invoice.user.email}", size: 10
    @pdf.move_down 20
  end

  def render_items_table
    table_data = build_table_data

    @pdf.table(table_data,
               header: true,
               width: @pdf.bounds.width,
               cell_style: { size: 9, padding: 5 }) do
      row(0).font_style = :bold
      row(0).background_color = 'EEEEEE'
      columns(3).align = :right
    end
  end

  def build_table_data
    data = [['日付', '患者名', '施術内容', '金額']]

    @invoice.invoice_items.includes(medical_record: :patient).each do |item|
      record = item.medical_record
      data << [
        record.visit_date.strftime('%Y/%m/%d'),
        record.patient.name,
        truncate_text(record.chief_complaint, 30),
        format_currency(item.amount)
      ]
    end

    data
  end

  def render_total
    @pdf.move_down 10
    @pdf.text "合計金額: #{format_currency(@invoice.total_amount)}",
              size: 16, style: :bold, align: :right
  end

  def render_footer
    @pdf.move_down 30
    @pdf.text '◆ お振込先', size: 10, style: :bold
    @pdf.text '銀行名: ○○銀行', size: 9
    @pdf.text '支店名: △△支店', size: 9
    @pdf.text '口座種別: 普通', size: 9
    @pdf.text '口座番号: 1234567', size: 9
    @pdf.text '口座名義: ヤマダ ハナコ', size: 9
    @pdf.move_down 10
    payment_due = (@invoice.issued_at + 30.days).strftime('%Y年%m月%d日')
    @pdf.text "お振込期限: #{payment_due}", size: 9
    @pdf.move_down 20
    @pdf.text '※ 振込手数料はご負担ください', size: 8, style: :italic
  end

  def format_currency(amount)
    "¥#{amount.to_i.to_s(:delimited)}"
  end

  def truncate_text(text, length)
    text.to_s.truncate(length, omission: '...')
  end
end
```

---

## 🎨 コントローラー設計

### InvoicesController

```ruby
# app/controllers/invoices_controller.rb
class InvoicesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_invoice, only: [:show, :edit, :update, :destroy, :generate_pdf, :download_pdf]

  def index
    @q = current_user.invoices.ransack(params[:q])
    @invoices = @q.result
                  .includes(:facility)
                  .recent
                  .page(params[:page])
                  .per(20)
  end

  def show
    @invoice_items = @invoice.invoice_items
                             .includes(medical_record: :patient)
                             .order('medical_records.visit_date ASC')
  end

  def new
    @invoice = Invoice.new
    @facilities = current_user.facilities.order(:name)
  end

  def create
    generator = InvoiceGenerator.new(
      user: current_user,
      facility: Facility.find(invoice_params[:facility_id]),
      start_date: Date.parse(invoice_params[:billing_period_start]),
      end_date: Date.parse(invoice_params[:billing_period_end])
    )

    @invoice = generator.generate

    if @invoice.persisted?
      redirect_to @invoice, notice: '請求書を作成しました。'
    else
      @facilities = current_user.facilities.order(:name)
      render :new, status: :unprocessable_entity
    end
  rescue ArgumentError => e
    @facilities = current_user.facilities.order(:name)
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  end

  def edit
    @facilities = current_user.facilities.order(:name)
  end

  def update
    if @invoice.update(invoice_params.except(:facility_id))
      redirect_to @invoice, notice: '請求書を更新しました。'
    else
      @facilities = current_user.facilities.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @invoice.destroy
    redirect_to invoices_path, notice: '請求書を削除しました。'
  end

  def generate_pdf
    pdf_data = InvoicePdfGenerator.new(@invoice).generate

    @invoice.pdf_file.attach(
      io: StringIO.new(pdf_data),
      filename: "invoice_#{@invoice.invoice_number}.pdf",
      content_type: 'application/pdf'
    )

    @invoice.update(status: :issued) if @invoice.draft?

    redirect_to @invoice, notice: 'PDFを生成しました。'
  rescue StandardError => e
    Rails.logger.error("PDF generation failed: #{e.message}")
    redirect_to @invoice, alert: 'PDF生成に失敗しました。'
  end

  def download_pdf
    if @invoice.pdf_file.attached?
      redirect_to rails_blob_path(@invoice.pdf_file, disposition: 'attachment'), allow_other_host: true
    else
      redirect_to @invoice, alert: 'PDFが生成されていません。'
    end
  end

  private

  def set_invoice
    @invoice = current_user.invoices.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to invoices_path, alert: '請求書が見つかりません。'
  end

  def invoice_params
    params.require(:invoice).permit(
      :facility_id,
      :billing_period_start,
      :billing_period_end,
      :status,
      :notes
    )
  end
end
```

---

## 📝 実装タスク分解

### Week 3（前半）: モデル層とサービス層

#### Day 1-2: モデル実装

- [ ] Invoice マイグレーション作成
- [ ] InvoiceItem マイグレーション作成
- [ ] Invoice モデル実装
  - [ ] リレーション設定
  - [ ] バリデーション実装
  - [ ] 請求書番号自動生成ロジック
  - [ ] 合計金額計算ロジック
  - [ ] Ransack 設定
- [ ] InvoiceItem モデル実装
  - [ ] リレーション設定
  - [ ] バリデーション実装
  - [ ] コールバック実装
- [ ] Model Spec 作成
  - [ ] Invoice 基本テスト (8-10 件)
  - [ ] InvoiceItem 基本テスト (5-7 件)

#### Day 3-4: サービスクラス実装

- [ ] InvoiceGenerator 実装
  - [ ] カルテ自動集計ロジック
  - [ ] 請求書明細作成ロジック
  - [ ] エラーハンドリング
- [ ] InvoiceGenerator Spec 作成 (8-10 件)
- [ ] IPAex ゴシックフォントのダウンロード・配置
- [ ] InvoicePdfGenerator 実装
  - [ ] 日本語フォント設定
  - [ ] PDF 各セクション実装
  - [ ] テーブルレイアウト
- [ ] InvoicePdfGenerator Spec 作成 (6-8 件)

### Week 3（後半）: コントローラー層とビュー層

#### Day 5-6: コントローラー実装

- [ ] InvoicesController 実装
  - [ ] index アクション
  - [ ] show アクション
  - [ ] new/create アクション
  - [ ] edit/update アクション
  - [ ] destroy アクション
  - [ ] generate_pdf アクション
  - [ ] download_pdf アクション
- [ ] ルーティング設定
- [ ] Request Spec 作成
  - [ ] 認証テスト (2 件)
  - [ ] CRUD 操作テスト (10-12 件)
  - [ ] PDF 生成テスト (4-5 件)

#### Day 7-8: ビュー実装

- [ ] 請求書一覧ビュー
  - [ ] 一覧表示
  - [ ] 検索フォーム（Ransack）
  - [ ] ページネーション
- [ ] 請求書詳細ビュー
  - [ ] 請求書情報表示
  - [ ] 明細テーブル
  - [ ] PDF 生成ボタン
  - [ ] ステータス変更機能
- [ ] 請求書作成フォーム
  - [ ] 施術場所選択
  - [ ] 請求期間入力
- [ ] 請求書編集フォーム
  - [ ] ステータス変更
  - [ ] 備考入力

### Week 4: テスト・統合・ドキュメント

#### Day 9-10: System Spec 実装

- [ ] 請求書一覧テスト (3-4 件)
- [ ] 請求書作成テスト (4-5 件)
- [ ] 請求書詳細テスト (3-4 件)
- [ ] PDF 生成テスト (2-3 件)
- [ ] 検索機能テスト (2-3 件)

#### Day 11-12: 統合テスト・バグ修正

- [ ] 全テスト実行・修正
- [ ] RuboCop 違反修正
- [ ] Brakeman 警告対応
- [ ] N+1 クエリ検出・修正（Bullet）
- [ ] パフォーマンステスト

#### Day 13-14: ドキュメント・PR 作成

- [ ] Phase 5-B 完了報告書作成
- [ ] データモデル図更新
- [ ] API 仕様書更新（必要に応じて）
- [ ] PR 作成
- [ ] コードレビュー対応
- [ ] マージ

---

## 🧪 テスト戦略

### Model Spec

#### Invoice モデル（8-10 件）

- バリデーションテスト
- 請求書番号自動生成テスト
- 合計金額計算テスト
- スコープテスト
- Ransack 設定テスト

#### InvoiceItem モデル（5-7 件）

- バリデーションテスト
- コールバックテスト
- リレーションテスト

### Service Spec

#### InvoiceGenerator（8-10 件）

- 正常系: 請求書生成成功
- 異常系: 施術場所なし
- 異常系: 請求期間不正
- 異常系: カルテなし
- エッジケース: 複数カルテの集計

#### InvoicePdfGenerator（6-8 件）

- PDF 生成成功テスト
- 日本語フォント設定テスト
- 各セクション出力テスト
- テーブルデータ正確性テスト

### Request Spec（15-20 件）

#### 認証テスト

- 未ログイン時のリダイレクト

#### CRUD 操作テスト

- GET /invoices: 一覧表示
- GET /invoices/new: 新規作成フォーム
- POST /invoices: 請求書作成
- GET /invoices/:id: 詳細表示
- GET /invoices/:id/edit: 編集フォーム
- PATCH /invoices/:id: 更新
- DELETE /invoices/:id: 削除

#### PDF 関連テスト

- POST /invoices/:id/generate_pdf: PDF 生成
- GET /invoices/:id/download_pdf: PDF ダウンロード

### System Spec（12-15 件）

#### 請求書一覧（3-4 件）

- 一覧表示の確認
- 検索機能の動作確認
- ページネーションの動作確認

#### 請求書作成（4-5 件）

- 新規作成フローの動作確認
- バリデーションエラーの表示確認
- 成功時のフラッシュメッセージ確認
- カルテが存在しない場合の動作確認

#### 請求書詳細（3-4 件）

- 詳細表示の確認
- 明細テーブルの表示確認
- ステータス変更機能の確認

#### PDF 生成（2-3 件）

- PDF 生成ボタンの動作確認
- PDF 生成成功時の動作確認
- PDF ダウンロードの動作確認

---

## 🔒 セキュリティ考慮事項

### 1. アクセス制御

- すべてのアクションで `authenticate_user!` を必須化
- `current_user` でスコープを限定
- 他ユーザーの請求書にアクセス不可

### 2. Strong Parameters

- 許可するパラメータの明示的な定義
- ネストしたパラメータの適切な制御

### 3. PDF 生成時のセキュリティ

- ファイル名のサニタイズ
- 不正なパスの防止
- ファイルサイズの制限

---

## ⚡ パフォーマンス最適化

### 1. N+1 クエリ対策

```ruby
# 請求書一覧
Invoice.includes(:facility).all

# 請求書詳細
Invoice.includes(invoice_items: { medical_record: :patient }).find(id)
```

### 2. インデックス設定

- `invoice_number` (unique)
- `user_id`
- `facility_id`
- `[facility_id, billing_period_start]` (composite)
- `status`

### 3. ページネーション

- Kaminari で 20 件/ページ
- 大量データでも高速表示

---

## 📊 成功基準

### 機能面

- [ ] 請求書の CRUD 操作が正常に動作する
- [ ] カルテから請求書を自動生成できる
- [ ] 日本語 PDF を生成できる
- [ ] 検索・フィルタリングが動作する

### 品質面

- [ ] テストカバレッジ 90%以上
- [ ] RuboCop 違反 0 件
- [ ] Brakeman 警告 0 件
- [ ] N+1 クエリ 0 件

### パフォーマンス面

- [ ] 請求書一覧の表示 < 500ms
- [ ] PDF 生成 < 3 秒
- [ ] 請求書作成 < 1 秒

---

## 🎓 学習ポイント

### 1. Prawn PDF 生成

- 日本語フォントの設定方法
- テーブルレイアウトの実装
- PDF のスタイリング

### 2. サービスオブジェクト

- 複雑なビジネスロジックの分離
- トランザクション処理
- エラーハンドリング

### 3. Active Storage

- ファイル添付の実装
- PDF ファイルの管理
- S3 との連携

---

## 🔗 関連リソース

### 公式ドキュメント

- **Prawn**: https://prawnpdf.org/docs/
- **Active Storage**: https://guides.rubyonrails.org/active_storage_overview.html
- **Ransack**: https://github.com/activerecord-hackery/ransack

### プロジェクト内ドキュメント

- **Phase 5 Overview**: `docs/phases/phase5/overview.md`
- **データモデル設計**: `docs/02_data_model.md`
- **詳細設計書**: `docs/07_detailed_design.md`

---

## 📝 次のステップ

### Week 3 開始時

1. ブランチ作成: `git checkout -b feature/p5b-invoice-generation`
2. マイグレーション作成開始
3. TDD サイクルでモデル実装

### Week 4 終了時

1. 全テスト実行: `bundle exec rspec`
2. RuboCop 実行: `bundle exec rubocop -A`
3. PR 作成: `gh pr create`
4. Phase 5-B 完了報告書作成

---

**作成者**: Claude Code
**最終更新**: 2025-10-15
**次のレビュー**: 実装開始時

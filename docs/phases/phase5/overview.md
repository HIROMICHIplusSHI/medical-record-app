# Phase 5: 売上管理・請求書機能 + 本番デプロイ

**作成日**: 2025-10-15
**最終更新**: 2025-10-19
**目標**: Phase 2未実装機能（売上管理・請求書生成・同意書）を完成させ、本番環境へデプロイする

---

## 🎯 Phase 5の目的

1. **売上管理ダッシュボード**: 月次・年次売上の可視化、施術場所別集計 ✅
2. **請求書生成機能**: 自動集計・PDF出力による請求書作成の効率化 ✅
3. **同意書機能**: テンプレート管理・電子署名・PDF出力 ✅
4. **パフォーマンス最適化**: 本番環境に向けた最終調整
5. **本番デプロイ**: Render.comへのデプロイと運用開始

---

## 📋 全体スケジュール（8週間）

| フェーズ | 内容 | 期間 | マイルストーン | 状態 |
|---------|------|------|--------------|------|
| **Phase 5-A** | 売上管理ダッシュボード | Week 1-2 | 売上集計・CSV出力 | ✅ 完了 |
| **Phase 5-B** | 請求書生成・PDF出力 | Week 3-4 | 請求書自動生成 | ✅ 完了 |
| **Phase 5-C** | 同意書機能 | Week 5-6 | 同意書PDF出力 | ✅ 完了 |
| **Phase 5-D** | パフォーマンス最適化 | Week 7 | DB最適化・監視設定 | 未実装 |
| **Phase 5-E** | 本番デプロイ | Week 8 | 運用開始 | 未実装 |

---

## Phase 5-A: 売上管理ダッシュボード（Week 1-2）

### 目標
施術場所ごとの売上を可視化し、月次・年次での集計を可能にする。

### 実装内容

#### 1. 売上集計ロジック（Model層）
**推定時間**: 3-4時間

```ruby
# app/models/medical_record.rb
class MedicalRecord < ApplicationRecord
  # スコープ
  scope :in_period, ->(start_date, end_date) {
    where(treatment_date: start_date..end_date)
  }
  scope :by_facility, ->(facility_id) { where(facility_id: facility_id) }
  scope :by_user, ->(user_id) {
    joins(:facility).where(facilities: { user_id: user_id })
  }

  # 売上集計メソッド
  def self.total_revenue(start_date, end_date)
    in_period(start_date, end_date).sum(:total_amount)
  end

  def self.revenue_by_facility(start_date, end_date)
    in_period(start_date, end_date)
      .joins(:facility)
      .group('facilities.id', 'facilities.name')
      .select('facilities.id, facilities.name, SUM(medical_records.total_amount) as revenue')
      .order('revenue DESC')
  end

  def self.monthly_revenue(year)
    (1..12).map do |month|
      start_date = Date.new(year, month, 1)
      end_date = start_date.end_of_month
      {
        month: month,
        revenue: total_revenue(start_date, end_date),
        count: in_period(start_date, end_date).count
      }
    end
  end
end
```

#### 2. ダッシュボードコントローラー
**推定時間**: 2-3時間

```ruby
# app/controllers/dashboards_controller.rb
class DashboardsController < ApplicationController
  before_action :authenticate_user!

  def index
    @year = params[:year]&.to_i || Date.current.year
    @month = params[:month]&.to_i

    # 期間設定
    if @month
      @start_date = Date.new(@year, @month, 1)
      @end_date = @start_date.end_of_month
    else
      @start_date = Date.new(@year, 1, 1)
      @end_date = Date.new(@year, 12, 31)
    end

    # 売上集計
    @total_revenue = current_user_records.total_revenue(@start_date, @end_date)
    @revenue_by_facility = current_user_records.revenue_by_facility(@start_date, @end_date)
    @monthly_data = current_user_records.monthly_revenue(@year) unless @month

    # 統計情報
    @total_records = current_user_records.in_period(@start_date, @end_date).count
    @total_patients = current_user_records.in_period(@start_date, @end_date)
                                          .distinct.count(:patient_id)
  end

  def export_csv
    @start_date = Date.parse(params[:start_date])
    @end_date = Date.parse(params[:end_date])

    records = current_user_records.in_period(@start_date, @end_date)
                                  .includes(:patient, :facility)
                                  .order(treatment_date: :desc)

    respond_to do |format|
      format.csv do
        send_data generate_csv(records),
                  filename: "revenue_#{@start_date}_#{@end_date}.csv",
                  type: 'text/csv; charset=utf-8'
      end
    end
  end

  private

  def current_user_records
    MedicalRecord.by_user(current_user.id)
  end

  def generate_csv(records)
    CSV.generate(headers: true, encoding: Encoding::SJIS) do |csv|
      csv << ['日付', '患者名', '施術場所', '施術内容', '金額']

      records.each do |record|
        csv << [
          record.treatment_date,
          record.patient.name,
          record.facility.name,
          record.treatment_content&.truncate(50),
          record.total_amount
        ]
      end
    end
  end
end
```

#### 3. ダッシュボードビュー
**推定時間**: 3-4時間

```erb
<!-- app/views/dashboards/index.html.erb -->
<div class="container mx-auto px-4 py-8">
  <h1 class="text-3xl font-bold mb-6">売上ダッシュボード</h1>

  <!-- 期間選択 -->
  <div class="mb-6 flex gap-4">
    <%= form_with url: dashboard_path, method: :get, class: "flex gap-2" do |f| %>
      <%= f.select :year, (Date.current.year - 5..Date.current.year).to_a.reverse,
                   { selected: @year }, class: "select select-bordered" %>
      <%= f.select :month, (1..12).map { |m| [m, m] },
                   { include_blank: "年間" }, class: "select select-bordered" %>
      <%= f.submit "表示", class: "btn btn-primary" %>
    <% end %>

    <%= link_to "CSV出力", export_csv_dashboard_path(
          start_date: @start_date, end_date: @end_date, format: :csv
        ), class: "btn btn-outline" %>
  </div>

  <!-- サマリーカード -->
  <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
    <div class="card bg-base-100 shadow">
      <div class="card-body">
        <h2 class="card-title text-sm">総売上</h2>
        <p class="text-3xl font-bold">¥<%= @total_revenue.to_i.to_s(:delimited) %></p>
      </div>
    </div>

    <div class="card bg-base-100 shadow">
      <div class="card-body">
        <h2 class="card-title text-sm">カルテ件数</h2>
        <p class="text-3xl font-bold"><%= @total_records %></p>
      </div>
    </div>

    <div class="card bg-base-100 shadow">
      <div class="card-body">
        <h2 class="card-title text-sm">患者数</h2>
        <p class="text-3xl font-bold"><%= @total_patients %></p>
      </div>
    </div>
  </div>

  <!-- 施術場所別売上 -->
  <div class="card bg-base-100 shadow mb-6">
    <div class="card-body">
      <h2 class="card-title">施術場所別売上</h2>
      <div class="overflow-x-auto">
        <table class="table">
          <thead>
            <tr>
              <th>施術場所</th>
              <th class="text-right">売上</th>
            </tr>
          </thead>
          <tbody>
            <% @revenue_by_facility.each do |data| %>
              <tr>
                <td><%= data.name %></td>
                <td class="text-right font-mono">
                  ¥<%= data.revenue.to_i.to_s(:delimited) %>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
  </div>

  <% if @monthly_data %>
    <!-- 月次推移テーブル -->
    <div class="card bg-base-100 shadow">
      <div class="card-body">
        <h2 class="card-title">月次推移（<%= @year %>年）</h2>
        <div class="overflow-x-auto">
          <table class="table">
            <thead>
              <tr>
                <th>月</th>
                <th class="text-right">売上</th>
                <th class="text-right">件数</th>
              </tr>
            </thead>
            <tbody>
              <% @monthly_data.each do |data| %>
                <tr>
                  <td><%= data[:month] %>月</td>
                  <td class="text-right font-mono">
                    ¥<%= data[:revenue].to_i.to_s(:delimited) %>
                  </td>
                  <td class="text-right"><%= data[:count] %></td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  <% end %>
</div>
```

#### 4. ルーティング
**推定時間**: 0.5時間

```ruby
# config/routes.rb
resource :dashboard, only: [:index] do
  get :export_csv
end
```

#### 5. RSpecテスト
**推定時間**: 3-4時間

```ruby
# spec/models/medical_record_spec.rb
RSpec.describe MedicalRecord, type: :model do
  describe '.total_revenue' do
    it '期間内の総売上を計算する' do
      # テスト実装
    end
  end

  describe '.revenue_by_facility' do
    it '施術場所別の売上を集計する' do
      # テスト実装
    end
  end

  describe '.monthly_revenue' do
    it '月次売上を配列で返す' do
      # テスト実装
    end
  end
end

# spec/requests/dashboards_spec.rb
RSpec.describe 'Dashboards', type: :request do
  describe 'GET /dashboard' do
    it 'ダッシュボードを表示する' do
      # テスト実装
    end
  end

  describe 'GET /dashboard/export_csv' do
    it 'CSV出力する' do
      # テスト実装
    end
  end
end
```

### マイルストーン達成条件

- [ ] 売上集計ロジック実装・テスト完了
- [ ] ダッシュボード画面表示完了
- [ ] 施術場所別売上表示完了
- [ ] CSV エクスポート機能完了
- [ ] RSpecテスト全て通過（カバレッジ80%以上）
- [ ] E2Eテスト完了

---

## Phase 5-B: 請求書生成・PDF出力（Week 3-4）

### 目標
施術場所ごとに月次請求書を自動生成し、PDF出力できるようにする。

### 実装内容

#### 1. Invoiceモデル作成
**推定時間**: 2-3時間

```ruby
# マイグレーション
rails g model Invoice \
  user:references \
  facility:references \
  invoice_number:string \
  billing_period_start:date \
  billing_period_end:date \
  total_amount:decimal \
  issued_at:datetime \
  status:integer

# app/models/invoice.rb
class Invoice < ApplicationRecord
  belongs_to :user
  belongs_to :facility
  has_many :invoice_items, dependent: :destroy
  has_one_attached :pdf_file

  enum :status, {
    draft: 0,
    issued: 1,
    sent: 2,
    paid: 3,
    cancelled: 9
  }

  validates :invoice_number, presence: true, uniqueness: true
  validates :billing_period_start, :billing_period_end, presence: true
  validates :total_amount, numericality: { greater_than_or_equal_to: 0 }

  before_validation :generate_invoice_number, on: :create
  before_save :calculate_total_amount

  scope :recent, -> { order(issued_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }

  def period
    "#{billing_period_start.strftime('%Y/%m/%d')} 〜 #{billing_period_end.strftime('%Y/%m/%d')}"
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
    self.total_amount = invoice_items.sum(&:subtotal)
  end
end

# app/models/invoice_item.rb
class InvoiceItem < ApplicationRecord
  belongs_to :invoice
  belongs_to :medical_record

  validates :description, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }

  def subtotal
    amount
  end
end
```

#### 2. 請求書生成サービス
**推定時間**: 3-4時間

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
    Invoice.transaction do
      invoice = create_invoice
      add_invoice_items(invoice)
      invoice.save!
      invoice
    end
  end

  private

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
    medical_records.each do |record|
      invoice.invoice_items.build(
        medical_record: record,
        description: "#{record.treatment_date} - #{record.patient.name}",
        amount: record.total_amount
      )
    end
  end

  def medical_records
    MedicalRecord.where(facility: @facility)
                 .where(treatment_date: @start_date..@end_date)
                 .order(treatment_date: :asc)
  end
end
```

#### 3. PDF生成サービス（Prawn）
**推定時間**: 4-5時間

```ruby
# app/services/invoice_pdf_generator.rb
class InvoicePdfGenerator
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
    font_path = Rails.root.join('app', 'assets', 'fonts', 'ipaexg.ttf')
    @pdf.font_families.update('IPAexGothic' => { normal: font_path.to_s })
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
    @pdf.move_down 20
  end

  def render_items_table
    table_data = [['日付', '患者名', '施術内容', '金額']]

    @invoice.invoice_items.includes(:medical_record).each do |item|
      record = item.medical_record
      table_data << [
        record.treatment_date.strftime('%Y/%m/%d'),
        record.patient.name,
        record.treatment_content&.truncate(30) || '-',
        "¥#{item.amount.to_i.to_s(:delimited)}"
      ]
    end

    @pdf.table(table_data,
               header: true,
               width: @pdf.bounds.width,
               cell_style: { size: 9, padding: 5 }) do
      row(0).font_style = :bold
      row(0).background_color = 'EEEEEE'
      columns(3).align = :right
    end
  end

  def render_total
    @pdf.move_down 10
    @pdf.text "合計金額: ¥#{@invoice.total_amount.to_i.to_s(:delimited)}",
              size: 16, style: :bold, align: :right
  end

  def render_footer
    @pdf.move_down 30
    @pdf.text '◆ お振込先', size: 10, style: :bold
    @pdf.text '銀行名: ○○銀行', size: 9
    @pdf.text '支店名: △△支店', size: 9
    @pdf.text '口座種別: 普通', size: 9
    @pdf.text '口座番号: 1234567', size: 9
    @pdf.move_down 10
    @pdf.text "お振込期限: #{(@invoice.issued_at + 30.days).strftime('%Y年%m月%d日')}", size: 9
  end
end
```

#### 4. InvoicesController
**推定時間**: 3-4時間

```ruby
# app/controllers/invoices_controller.rb
class InvoicesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_invoice, only: [:show, :edit, :update, :destroy, :download_pdf, :generate_pdf]

  def index
    @q = current_user.invoices.ransack(params[:q])
    @invoices = @q.result.includes(:facility).recent.page(params[:page])
  end

  def show
  end

  def new
    @invoice = Invoice.new
    @facilities = current_user.facilities
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
      render :new, status: :unprocessable_entity
    end
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
  end

  def download_pdf
    if @invoice.pdf_file.attached?
      redirect_to rails_blob_path(@invoice.pdf_file, disposition: 'attachment')
    else
      redirect_to @invoice, alert: 'PDFが生成されていません。'
    end
  end

  private

  def set_invoice
    @invoice = current_user.invoices.find(params[:id])
  end

  def invoice_params
    params.require(:invoice).permit(:facility_id, :billing_period_start, :billing_period_end)
  end
end
```

#### 5. 日本語フォント設定
**推定時間**: 1-2時間

```bash
# IPAexゴシックフォントのダウンロード
mkdir -p app/assets/fonts
cd app/assets/fonts
wget https://moji.or.jp/wp-content/ipafont/IPAexfont/ipaexg00401.zip
unzip ipaexg00401.zip
mv ipaexg00401/ipaexg.ttf ./
rm -rf ipaexg00401*

# .gitignore に追加しない（フォントファイルはリポジトリに含める）
```

#### 6. RSpecテスト
**推定時間**: 4-5時間

```ruby
# spec/services/invoice_generator_spec.rb
# spec/services/invoice_pdf_generator_spec.rb
# spec/models/invoice_spec.rb
# spec/requests/invoices_spec.rb
```

### マイルストーン達成条件

- [ ] Invoice/InvoiceItemモデル実装完了
- [ ] 請求書自動生成ロジック完了
- [ ] PDF生成機能完了
- [ ] 日本語フォント対応完了
- [ ] 請求書一覧・詳細画面完了
- [ ] RSpecテスト全て通過
- [ ] E2Eテスト完了

---

## Phase 5-C: 同意書機能（Week 5-6）✅ 完了

### 実装状況
**完了日**: 2025-10-19
**PR**: #19, #20, #21, #22
**総合統計**:
- 実装期間: 3日間
- 追加コード: 約2,500行
- テスト: 683 examples, 0 failures
- コード品質: RuboCop 0違反、Brakeman 0警告

### 実装内容

#### Phase 5-C-1: データモデル基盤（PR #19）
- `PatientConsent` モデル（同意書）
- `ConsentFormTemplate` モデル（同意書テンプレート）
- `ConsentFormItem` モデル（チェック項目）
- `ConsentItemResponse` モデル（チェック回答）
- `FacilityDoctor` モデル（施設医師）
- Active Record Encryption による署名データ暗号化
- Model Spec完備

#### Phase 5-C-2: 同意書テンプレート管理（PR #20）
- 同意書テンプレートCRUD機能
- チェック項目の動的追加・削除（Stimulus）
- テンプレート一覧・詳細画面
- Request/System Spec完備

#### Phase 5-C-3: 施設医師情報管理（PR #21）
- 施設医師CRUD機能
- 医師情報の施設関連付け
- 医師一覧・詳細画面

#### Phase 5-C-4: 同意書PDF出力機能（PR #22）
- 同意書作成機能（カルテ連携）
- 電子署名機能（Canvas）
- PDF生成機能（Prawn + Noto Sans JP）
- `PatientConsentPdfGenerator` サービスクラス
- PDFプレビュー機能
- 同意書一覧・詳細画面
- コードレビュー対応（セキュリティ強化）

### マイルストーン達成状況
- ✅ 同意書データモデル完成
- ✅ 同意書テンプレート管理完成
- ✅ 施設医師情報管理完成
- ✅ 同意書PDF出力完成
- ✅ 電子署名機能完成
- ✅ RSpecテスト全て通過
- ✅ コードレビュー対応完了

---

## Phase 5-D: パフォーマンス最適化（Week 7）

### 目標
本番環境に向けたパフォーマンス最適化と監視設定。

### 実装内容

#### 1. データベース最適化
**推定時間**: 2-3時間

- インデックス追加
- N+1クエリ解消（Bullet gem活用）
- クエリ最適化

#### 2. パフォーマンス測定
**推定時間**: 2時間

- Lighthouse実行
- rack-mini-profiler導入

#### 3. エラーハンドリング強化
**推定時間**: 2時間

- カスタム404/500ページ
- エラー通知設定

#### 4. ドキュメント作成
**推定時間**: 3-4時間

- ユーザーマニュアル
- 運用手順書

### マイルストーン達成条件

- [ ] インデックス最適化完了
- [ ] N+1クエリ0件
- [ ] Lighthouse Performance 90点以上
- [ ] ユーザーマニュアル完成

---

## Phase 5-E: 本番デプロイ（Week 8）

### 目標
Render.comへデプロイし、運用開始する。

### 実装内容

#### 1. Render環境構築
**推定時間**: 2-3時間

- Renderアカウント作成
- PostgreSQL DB作成
- Redis作成（オプション）

#### 2. 環境変数設定
**推定時間**: 1-2時間

- RAILS_MASTER_KEY
- AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY
- GOOGLE_CLIENT_ID / GOOGLE_CLIENT_SECRET

#### 3. AWS S3 / Cloudflare R2設定
**推定時間**: 2-3時間

- バケット作成
- 権限設定
- Active Storage設定

#### 4. デプロイ実行
**推定時間**: 2-3時間

- Render.com設定
- デプロイ実行
- マイグレーション実行

#### 5. 動作確認
**推定時間**: 3-4時間

- 全機能の動作確認
- データ投入テスト
- パフォーマンステスト

### マイルストーン達成条件

- [ ] 本番環境デプロイ完了
- [ ] 全機能動作確認完了
- [ ] 初期データ投入完了
- [ ] 運用監視設定完了
- [ ] ユーザー引き渡し完了

---

## 📊 Phase 5全体の成功基準

### 機能面
- [ ] 売上ダッシュボード完成
- [ ] 請求書生成・PDF出力完成
- [ ] CSV エクスポート完成
- [ ] 本番環境稼働

### 品質面
- [ ] テストカバレッジ 80%以上維持
- [ ] RuboCop違反 0件
- [ ] Brakeman警告 0件
- [ ] Lighthouse Performance 90点以上

### 運用面
- [ ] ユーザーマニュアル完成
- [ ] 運用手順書完成
- [ ] エラー監視設定完了
- [ ] バックアップ設定完了

---

**次のステップ**: Phase 5-Aから順次実装開始

**作成者**: Claude
**最終更新**: 2025-10-15

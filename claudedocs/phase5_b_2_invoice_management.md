# Phase 5-B-2: 請求書管理機能実装

## 実装日
2025-10-16

## 概要
請求書の基本的なCRUD機能、請求明細の自動生成、検索・ページネーション機能を実装しました。

## 実装内容

### 1. コントローラ実装
**ファイル**: `app/controllers/invoices_controller.rb`

#### 主要アクション
- `index`: 請求書一覧（検索・ページネーション対応）
- `show`: 請求書詳細と請求明細表示
- `new/create`: 新規請求書作成と明細の自動生成
- `edit/update`: 請求書編集（ステータス更新）
- `destroy`: 請求書削除
- `refresh_items`: 請求明細の再生成（ドラフト状態のみ）
- `generate_pdf/download_pdf`: PDF生成スタブ（Phase 5-B-3で実装予定）

#### データ整合性の改善（コードレビュー対応）
1. **トランザクション管理**
   - 請求書作成時と明細更新時にトランザクションを使用
   - カルテ0件の場合は自動ロールバック

2. **メソッド分割**（Rubocop Metrics/MethodLength対応）
   ```ruby
   # createアクションをリファクタリング
   def build_new_invoice
     # 新規請求書インスタンスの構築
   end

   def save_invoice_with_items
     # トランザクション内で保存と明細生成
   end

   def create_invoice_items_from_medical_records
     # 期間内のカルテから明細を自動生成
     # 作成件数を返却（バリデーション用）
   end
   ```

3. **カルテ0件のバリデーション**
   - 該当期間にカルテが見つからない場合はエラー表示
   - `ActiveRecord::Rollback`でロールバック

### 2. モデル実装

#### Invoice モデル (`app/models/invoice.rb`)
**アソシエーション**:
- `belongs_to :user`
- `belongs_to :facility`
- `has_many :invoice_items, dependent: :destroy`

**バリデーション**:
- 請求書番号の一意性
- 発行日、請求期間の必須チェック
- 請求期間の妥当性（終了日 >= 開始日）

**ステータス管理**（enum）:
- `draft`: ドラフト（編集・削除可能）
- `issued`: 発行済み（編集のみ可能）
- `sent`: 送信済み
- `paid`: 支払済み
- `cancelled`: キャンセル

**主要メソッド**:
- `generate_invoice_number`: 請求書番号自動生成（INV-YYYYMM-XXXX形式）
- `calculate_total_amount`: 請求明細の合計金額計算
- `can_edit?/can_delete?/can_refresh_items?`: 権限チェック

**スコープ**:
- `recent`: 発行日降順
- `by_status`: ステータスでフィルタ
- `by_facility`: 施設でフィルタ
- `by_period`: 請求期間でフィルタ

#### InvoiceItem モデル (`app/models/invoice_item.rb`)
**アソシエーション**:
- `belongs_to :invoice`
- `belongs_to :medical_record`

**バリデーション**:
- 説明文の必須チェック
- 金額の数値チェック（>= 0）
- invoice_id + medical_record_idの一意性制約

**コールバック**:
- 明細の作成・更新・削除時に請求書の合計金額を自動更新

#### Facility モデル改善 (`app/models/facility.rb`)
**アソシエーション有効化**（コードレビュー対応）:
```ruby
has_many :invoices, dependent: :restrict_with_error
```

**Ransack設定**:
```ruby
def self.ransackable_associations(_auth_object = nil)
  %w[invoices medical_records user]  # invoicesを追加
end
```

### 3. ビュー実装

#### 一覧画面 (`app/views/invoices/index.html.erb`)
- カードレイアウトで請求書を表示
- Ransackによる高度な検索フォーム：
  - 請求書番号（部分一致）
  - 施設（完全一致）
  - ステータス（完全一致）
  - 請求期間（範囲検索）
- Kaminariによるページネーション（20件/ページ）
- Tom Selectによる検索UIの強化

#### 詳細画面 (`app/views/invoices/show.html.erb`)
- 請求書基本情報の表示
- 請求明細の一覧表示（カルテ情報含む）
- ステータスに応じた操作ボタン：
  - 編集（draft/issuedのみ）
  - 削除（draftのみ）
  - 明細更新（draftのみ）
  - PDF生成（スタブ）

#### フォーム画面 (`app/views/invoices/_form.html.erb`)
- 施設選択（Tom Select）
- 請求期間選択（日付ピッカー）
- ステータス選択（編集時のみ、Tom Select）
- 備考入力

### 4. ルーティング (`config/routes.rb`)
```ruby
resources :invoices do
  member do
    post :generate_pdf
    get :download_pdf
    post :refresh_items
  end
end
```

### 5. テスト実装

#### Request Specs (`spec/requests/invoices_spec.rb`)
- 認証チェック（全アクション）
- CRUD操作のテスト
- 自分の請求書のみアクセス可能
- ページネーション動作確認
- 施設一覧の取得確認

#### System Specs (`spec/system/invoice_workflows_spec.rb`)
- 請求書作成・閲覧・更新・削除の統合フロー
- 検索機能のテスト：
  - ステータス検索
  - 請求書番号検索
  - 請求期間検索
- PDF機能スタブの確認
- 権限による削除制御
- ページネーション（20件ずつ表示）
- Tom Select対応の検索UI

#### Model Specs
- Invoice: `spec/models/invoice_spec.rb`
- InvoiceItem: `spec/models/invoice_item_spec.rb`

**テスト結果**: 454 examples, 0 failures, 11 pending

### 6. ナビゲーション統合
**ヘッダーメニュー** (`app/views/shared/_header.html.erb`):
```erb
<%= link_to "請求書", invoices_path, class: "..." %>
```

**System Spec** (`spec/system/header_navigation_spec.rb`):
- 請求書リンクの表示確認
- 請求書一覧への遷移テスト

### 7. 品質改善

#### Rubocop対応
- `Metrics/MethodLength`違反の解消
- メソッドの適切な分割
- 全ファイル77件、違反0件

#### Brakeman
- セキュリティスキャン: Pass
- 脆弱性検出なし

#### テストの安定化
1. **請求書検索テスト**
   - タイミング問題の修正
   - 不要な請求書が消えるのを待つ明示的な待機条件追加

2. **患者ページネーションテスト**
   - 明示的な患者名を使用してテスト間の干渉を防止
   - CI環境での安定性向上

## 技術仕様

### 請求書番号フォーマット
```
INV-YYYYMM-XXXX
例: INV-202510-0001
```
- YYYY: 年（4桁）
- MM: 月（2桁）
- XXXX: 連番（4桁、月ごとにリセット）

### 請求明細の自動生成ロジック
```ruby
# 指定された施設・期間のカルテから明細を自動作成
medical_records = MedicalRecord
  .where(user: current_user)
  .where(facility_id: @invoice.facility_id)
  .where(visit_date: billing_period_start..billing_period_end)
  .includes(:cost_items)

# 各カルテから明細を作成
medical_records.each do |record|
  @invoice.invoice_items.create!(
    medical_record: record,
    description: build_invoice_item_description(record),
    amount: record.total_cost
  )
end
```

### 請求明細の内容生成
```ruby
# コスト項目の内訳を生成
record.cost_items.map do |item|
  formatted_price = item.total_price.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  "#{item.item_name} x #{item.quantity}: ¥#{formatted_price}"
end.join("\n")
```

## データベーススキーマ

### invoices テーブル
```ruby
create_table "invoices" do |t|
  t.bigint "user_id", null: false
  t.bigint "facility_id", null: false
  t.string "invoice_number", null: false
  t.datetime "issued_at", null: false
  t.date "billing_period_start", null: false
  t.date "billing_period_end", null: false
  t.integer "status", default: 0, null: false
  t.decimal "total_amount", precision: 10, scale: 2, default: "0.0", null: false
  t.text "notes"
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
  t.index ["facility_id"]
  t.index ["invoice_number"], unique: true
  t.index ["user_id"]
end
```

### invoice_items テーブル
```ruby
create_table "invoice_items" do |t|
  t.bigint "invoice_id", null: false
  t.bigint "medical_record_id", null: false
  t.text "description", null: false
  t.decimal "amount", precision: 10, scale: 2, null: false
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
  t.index ["invoice_id"]
  t.index ["medical_record_id"]
  t.index ["invoice_id", "medical_record_id"], unique: true
end
```

## 残課題（Phase 5-B-3で実装予定）

1. **PDF生成機能**
   - Prawnを使用したPDF生成
   - 請求書フォーマットのデザイン
   - ダウンロード機能

2. **メール送信機能**
   - 請求書送信のメール機能
   - ActionMailer設定

## コミット履歴

1. `refactor: コードレビュー対応 - データ整合性とアソシエーション改善`
   - トランザクション管理の追加
   - Facilityアソシエーションの有効化
   - カルテ0件のバリデーション追加

2. `fix: Rubocop違反修正とテストの安定化`
   - InvoicesController#createメソッドのリファクタリング
   - 請求書番号検索テストのタイミング問題修正

3. `fix: 患者ページネーションテストの堅牢性向上`
   - 明示的な患者名使用でテスト間干渉を防止
   - CI環境での安定性向上

## Pull Request
- PR #17: Phase 5-B-2: 請求書管理機能実装
- Status: CI Pass（RSpec & RuboCop, Brakeman）
- Code Review: A- (優秀) - 高品質、プロダクション準備完了

## 参考資料
- コードレビュー詳細: `claudedocs/code_review_phase5_b_2_invoices.md`
- 関連Issue: Phase 5-B (請求書管理)

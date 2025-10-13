# Phase 3 PR分割ワークフロー

**作成日**: 2025-10-13  
**戦略**: 1機能1PR - 小さく、独立して、段階的に

---

## 概要

Phase 3を**9つの独立したPR**に分割し、各PRは単一機能に集中します。

**メリット:**
- レビューが容易
- 問題の切り分けが簡単
- CI/CDが常にグリーン
- 段階的な実装・デプロイ可能

---

## PR一覧

| # | ブランチ名 | 機能 | サイズ | 期間 |
|---|-----------|------|--------|------|
| 1 | `feature/p3-01-cost-sheet` | コストシート管理 | Small | Day 1-2 |
| 2 | `feature/p3-02-medical-record-basic` | カルテ基本(コスト項目なし) | Medium | Day 3-5 |
| 2.5 | `feature/p3-02b-questionnaire-ui` | 問診票チェックボックスUI有効化 | Extra Small | Day 6 (30min) |
| 3 | `feature/p3-03-cost-item-nested` | コスト項目 + nested | Large | Day 7-9 |
| 4 | `feature/p3-04-dynamic-form` | 動的フォーム(cocoon) | Medium | Day 10 |
| 5 | `feature/p3-05-stimulus-calculator` | Stimulus自動計算 | Small | Day 11 |
| 6 | `feature/p3-06-active-storage` | 画像アップロード | Medium | Day 12-13 |
| 7 | `feature/p3-07-tags` | タグ機能 | Small | Day 14 |
| 8 | `feature/p3-08-search-e2e` | 検索強化 + E2E | Medium | Day 15-16 |

---

## PR #1: コストシート管理

### ブランチ作成

```bash
git checkout main
git pull origin main
git checkout -b feature/p3-01-cost-sheet
```

### 実装内容

- ✅ Phase 3ドキュメント整備（mainで更新されたものを含める）
- ✅ CostSheetモデル（バリデーション、スコープ）
- ✅ CostSheetsコントローラー（CRUD）
- ✅ ビュー（一覧、フォーム）
- ✅ テスト（モデル、リクエスト）
- ✅ シードデータ
- ✅ 日本語化

### 実装ファイル

```
docs/phases/phase3/implementation_guide.md (Phase 3実装ガイド - mainで更新済み)
docs/phases/phase3/pr_workflow.md (PRワークフロー - mainで更新済み)
db/migrate/YYYYMMDDHHMMSS_create_cost_sheets.rb
app/models/cost_sheet.rb
app/controllers/cost_sheets_controller.rb
app/views/cost_sheets/
  ├── index.html.erb
  ├── new.html.erb
  ├── edit.html.erb
  └── _form.html.erb
spec/models/cost_sheet_spec.rb
spec/requests/cost_sheets_spec.rb
spec/factories/cost_sheets.rb
config/locales/ja.yml (追加)
config/routes.rb (resources :cost_sheets)
db/seeds.rb (コストシートデータ追加)
```

### テスト実行

```bash
bundle exec rspec spec/models/cost_sheet_spec.rb
bundle exec rspec spec/requests/cost_sheets_spec.rb
bundle exec rubocop -A
```

### ブラウザ確認

```bash
rails s
# http://localhost:3000/cost_sheets
# - 新規登録
# - 一覧表示
# - 編集・削除
```

### コミット・PR作成

```bash
git add .
git commit -m "feat(cost_sheet): コストシート機能実装

- Phase 3ドキュメント整備（実装ガイド、PRワークフロー）
- CostSheetモデル実装（バリデーション、スコープ）
- CostSheetsコントローラー実装（CRUD）
- ビュー実装（一覧、フォーム）
- テスト実装（モデル15+、リクエスト18+）
- シードデータ追加
- カテゴリ管理（施術、薬剤、消耗品、その他）

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

git push -u origin feature/p3-01-cost-sheet
```

### PR作成とAIコードレビュー

**タイトル**: `Phase 3-01: コストシート管理機能実装`

**本文**:

```markdown
## 概要
Phase 3の最初の機能として、コストシート（料金テンプレート）管理機能を実装しました。

## 実装内容
- [x] Phase 3ドキュメント整備（実装ガイド、PRワークフロー）
  - PR #2.5（問診票UI有効化）の追記
  - Day番号調整
- [x] CostSheetモデル実装
  - バリデーション（項目名、標準価格）
  - スコープ（by_name, recent, by_category）
  - カテゴリ管理（treatment, medicine, supplies, other）
- [x] CostSheetsコントローラー実装（CRUD）
- [x] ビュー実装（一覧、新規、編集）
- [x] テスト実装（モデル、リクエスト）
- [x] シードデータ（7種類のサンプルデータ）
- [x] 日本語化

## テスト結果
- モデルスペック: 15/15 成功 ✅
- リクエストスペック: 18/18 成功 ✅
- RuboCop: 0違反 ✅

## 動作確認
- [x] ローカル環境で動作確認済み
- [x] ブラウザでCRUD操作確認済み
  - 新規登録
  - 一覧表示（カテゴリ、価格表示）
  - 編集・削除
- [x] 既存機能に影響なし（Facility, Patient継続動作）

## スクリーンショット
[コストシート一覧画面のスクショ]

## 次のPR
PR #2: カルテ基本機能実装（コスト項目なし）

## 関連
- 実装ガイド: `docs/phases/phase3/implementation_guide.md` (Day 1-2)

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
```

### AIコードレビュー実施（Claude Code）

PR作成後、Claude Codeを使ってコードレビューを実施します。

#### 1. レビュー実行

Claude Codeに以下のように依頼:

```
質問: 「自分で実装した機能をコードレビューしてください」
```

Claude Codeは`Task`ツールの`quality-engineer`サブエージェントを使用して以下を分析:
- **Critical**: セキュリティ、認可、データ整合性の問題
- **Minor**: コード品質、ベストプラクティス、保守性の改善点

#### 2. レビュー結果をPRにコメント

```bash
# レビュー結果をPRにコメントとして投稿
gh pr review <PR番号> --comment -b "$(cat <<'EOF'
## AIコードレビュー結果

### Critical Issues
1. **認可テスト不足**
   - 他ユーザーのリソースへのアクセス制御テストが必要
   - edit, update, deleteアクションの認可テスト追加

### Minor Issues
1. カテゴリバリデーション追加推奨
2. 非推奨ステータスコード更新（:unprocessable_content使用）

### Good Points
- ✅ テストカバレッジ充実
- ✅ スコープ実装適切
- ✅ バリデーション基本完備
EOF
)"
```

#### 3. Criticalな問題を修正

```bash
# 認可テストを追加
# spec/requests/cost_sheets_spec.rb に追加
describe '他のユーザーのリソースへのアクセス' do
  let(:other_user) { create(:user) }
  let(:other_cost_sheet) { create(:cost_sheet, user: other_user) }

  it '他のユーザーのコストシートを編集できない' do
    get edit_cost_sheet_path(other_cost_sheet)
    expect(response).to have_http_status(:not_found)
  end

  it '他のユーザーのコストシートを更新できない' do
    original_name = other_cost_sheet.item_name
    patch cost_sheet_path(other_cost_sheet), params: { cost_sheet: { item_name: 'hacked' } }
    expect(response).to have_http_status(:not_found)
    expect(other_cost_sheet.reload.item_name).to eq(original_name)
  end

  it '他のユーザーのコストシートを削除できない' do
    other_cost_sheet_id = other_cost_sheet.id
    delete cost_sheet_path(other_cost_sheet)
    expect(response).to have_http_status(:not_found)
    expect(CostSheet.exists?(other_cost_sheet_id)).to be true
  end
end

# Minorな問題も対応
# app/models/cost_sheet.rb にバリデーション追加
validates :category, inclusion: { in: CATEGORIES.keys, allow_blank: true }

# app/controllers/cost_sheets_controller.rb のステータスコード更新
render :new, status: :unprocessable_content  # was :unprocessable_entity
render :edit, status: :unprocessable_content  # was :unprocessable_entity
```

#### 4. テスト実行・コミット

```bash
# 全テスト実行
bundle exec rspec
bundle exec rubocop -A

# コミット
git add .
git commit -m "refactor: コードレビュー指摘事項の対応

- 認可テスト追加（他ユーザーのリソースアクセス制御）
- カテゴリバリデーション追加
- ステータスコード更新（:unprocessable_content）

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

git push
```

#### 5. PRマージ

全てのCIチェックが成功したらマージ:

```bash
gh pr merge <PR番号> --squash
```

---

## PR #2: カルテ基本機能（コスト項目なし）

### ブランチ作成

```bash
git checkout main
git pull origin main  # PR #1マージ後
git checkout -b feature/p3-02-medical-record-basic
```

### 実装内容

- ✅ MedicalRecordモデル（基本）
- ✅ Patient, Facilityとの関連（has_many追加）
- ✅ MedicalRecordsコントローラー（CRUD）
- ✅ ビュー（一覧、詳細、フォーム）
- ✅ テスト（モデル、リクエスト）
- ✅ 日本語化

### 実装ファイル

```
db/migrate/YYYYMMDDHHMMSS_create_medical_records.rb
app/models/medical_record.rb
app/models/patient.rb (has_many :medical_records追加)
app/models/facility.rb (has_many :medical_records追加)
app/models/user.rb (has_many :medical_records追加)
app/controllers/medical_records_controller.rb
app/views/medical_records/
  ├── index.html.erb
  ├── show.html.erb
  ├── new.html.erb
  ├── edit.html.erb
  └── _form.html.erb
spec/models/medical_record_spec.rb
spec/requests/medical_records_spec.rb
spec/factories/medical_records.rb
config/locales/ja.yml (medical_record追加)
config/routes.rb (resources :medical_records)
```

### テスト実行

```bash
bundle exec rspec spec/models/medical_record_spec.rb
bundle exec rspec spec/requests/medical_records_spec.rb
# 既存テストも全て実行（関連追加のため）
bundle exec rspec spec/models/patient_spec.rb
bundle exec rspec spec/models/facility_spec.rb
bundle exec rubocop -A
```

### コミット・PR

```bash
git add .
git commit -m "feat(medical_record): カルテ基本機能実装

- MedicalRecordモデル実装
- Patient, Facilityとの関連設定
- 基本CRUD機能（コスト項目・画像なし）
- テスト実装（モデル12+、リクエスト20+）

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

git push -u origin feature/p3-02-medical-record-basic
```

**PRタイトル**: `Phase 3-02: カルテ基本機能実装`

---

## PR #2.5: 問診票チェックボックスUI有効化

### 背景

Phase 2で実装済みの問診票チェックボックスUI（`_form_checkbox.html.erb`）を有効化します。
現在は`USE_CHECKBOX_UI = false`でテキストエリア版を使用していますが、カルテ機能実装後に切り替えます。

### ブランチ作成

```bash
git checkout main
git pull origin main  # PR #2マージ後
git checkout -b feature/p3-02b-questionnaire-ui
```

### 実装内容

- ✅ `USE_CHECKBOX_UI`フラグを`true`に変更
- ✅ カルテページから問診票へのリンク追加（任意）
- ✅ ブラウザでチェックボックスUI動作確認
- ✅ システムスペック実行（既存テスト）

### 実装ファイル

```
app/controllers/questionnaires_controller.rb (USE_CHECKBOX_UI: false → true)
app/views/medical_records/show.html.erb (問診票リンク追加 - 任意)
```

**注意**: `_form_checkbox.html.erb`（31KB）は既に実装済みのため、新規ファイル作成は不要

### テスト実行

```bash
# 既存の問診票テストを実行（チェックボックスUI対応済み）
bundle exec rspec spec/system/questionnaires_spec.rb
bundle exec rspec spec/requests/questionnaires_spec.rb
bundle exec rspec spec/models/questionnaire_spec.rb
bundle exec rubocop -A
```

### ブラウザ確認

```bash
rails s
# 1. 患者詳細ページから「問診票作成」
# 2. チェックボックスUIが表示されることを確認
# 3. 各項目にチェックを入れて保存
# 4. 問診票詳細ページで内容確認
```

**確認ポイント**:
- ✅ 既往歴、アレルギー、服薬歴がチェックボックス形式
- ✅ iPadでタッチ操作しやすい大きなボタン
- ✅ 保存後の表示が正常
- ✅ 既存のテキストエリア版のデータも表示可能（後方互換性）

### コミット・PR

```bash
git add .
git commit -m "feat(questionnaire): チェックボックスUI有効化

- USE_CHECKBOX_UIフラグをtrueに変更
- Phase 2で実装済みのチェックボックスUIを有効化
- iPadでの入力操作性向上
- 既存データとの後方互換性維持

Phase 2で実装した_form_checkbox.html.erbを有効化

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

git push -u origin feature/p3-02b-questionnaire-ui
```

### PR作成

**タイトル**: `Phase 3-02b: 問診票チェックボックスUI有効化`

**本文**:

```markdown
## 概要
Phase 2で実装済みの問診票チェックボックスUIを有効化します。

## 背景
Phase 2で実装した`_form_checkbox.html.erb`（31KB）は、フィーチャーフラグ`USE_CHECKBOX_UI = false`により無効化されていました。
Phase 3でカルテ機能が実装されたため、問診票とカルテの連携を強化する目的でチェックボックスUIを有効化します。

## 実装内容
- [x] `USE_CHECKBOX_UI`を`false`→`true`に変更
- [x] ブラウザでチェックボックスUI動作確認
- [x] 既存テスト実行（全て成功）
- [x] 後方互換性確認（既存データも正常表示）

## 変更内容
- `app/controllers/questionnaires_controller.rb`: 1行変更
  ```ruby
  # Before
  USE_CHECKBOX_UI = false
  
  # After
  USE_CHECKBOX_UI = true
  ```

## テスト結果
- システムスペック: 8/8 成功 ✅
- リクエストスペック: 10/10 成功 ✅
- モデルスペック: 15/15 成功 ✅
- RuboCop: 0違反 ✅

## 動作確認
- [x] チェックボックスUIが表示される
- [x] 既往歴、アレルギー、服薬歴の入力が容易
- [x] iPadでのタッチ操作性良好
- [x] 保存・表示が正常動作
- [x] 既存のテキストエリア版データも表示可能

## スクリーンショット
[チェックボックスUI表示画面のスクショ]

## メリット
- 📱 iPadでの入力操作性大幅向上
- ✅ チェックボックスによる構造化データ入力
- 🔄 既存データとの後方互換性維持
- 🎯 カルテ連携の準備完了

## 影響範囲
- **変更**: 問診票フォームUIのみ（1フラグ変更）
- **影響なし**: 既存の患者管理、施設管理機能
- **後方互換**: 既存のテキストエリア版データも正常表示

## 次のPR
PR #3: コスト項目 + nested attributes実装

## 関連
- Phase 2実装ガイド: `docs/phases/phase2/implementation_guide.md`
- フォームファイル: `app/views/questionnaires/_form_checkbox.html.erb`

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
```

---

## PR #3: コスト項目 + nested attributes

### ブランチ作成

```bash
git checkout main
git pull origin main  # PR #2マージ後
git checkout -b feature/p3-03-cost-item-nested
```

### 実装内容

- ✅ CostItemモデル
- ✅ nested_attributes_for設定
- ✅ 小計・合計の自動計算（callbacks）
- ✅ テスト（nested attributes含む）

### 実装ファイル

```
db/migrate/YYYYMMDDHHMMSS_create_cost_items.rb
app/models/cost_item.rb
app/models/medical_record.rb (更新)
  - has_many :cost_items
  - accepts_nested_attributes_for
  - after_save :update_total_amount
spec/models/cost_item_spec.rb
spec/models/medical_record_spec.rb (nested tests追加)
spec/factories/cost_items.rb
Gemfile (cocoon追加 - 次のPRで使用)
```

### 注意点

**この段階ではビューは更新しない** - モデル層のみ実装し、ビューは次のPR（#4）で対応

### テスト実行

```bash
bundle exec rspec spec/models/cost_item_spec.rb
bundle exec rspec spec/models/medical_record_spec.rb
bundle exec rubocop -A
```

### コミット・PR

```bash
git add .
git commit -m "feat(cost_item): コスト項目とnested attributes実装

- CostItemモデル実装（小計自動計算）
- MedicalRecordにnested attributes設定
- カルテ合計金額の自動更新（callbacks）
- テスト完備（CostItem15+、nested10+）

Note: ビューは次のPR(#4)で実装

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

git push -u origin feature/p3-03-cost-item-nested
```

**PRタイトル**: `Phase 3-03: コスト項目とnested attributes実装`

---

## PR #4: 動的フォーム（cocoon）

### ブランチ作成

```bash
git checkout main
git pull origin main  # PR #3マージ後
git checkout -b feature/p3-04-dynamic-form
```

### 実装内容

- ✅ cocoon gem統合
- ✅ 動的なコスト項目追加・削除フォーム
- ✅ コントローラーのStrong Parameters更新
- ✅ ビュー更新

### 実装ファイル

```
Gemfile (cocoon確認)
app/javascript/application.js (cocoon import)
app/controllers/medical_records_controller.rb (strong params更新)
app/views/medical_records/_form.html.erb (更新)
app/views/medical_records/_cost_item_fields.html.erb (新規)
spec/system/medical_records_basic_spec.rb (新規 - 基本的な動作確認)
```

### テスト実行

```bash
bundle install  # cocoon確認
bundle exec rspec
bundle exec rubocop -A
rails s  # ブラウザで動作確認
```

### コミット・PR

```bash
git add .
git commit -m "feat(ui): 動的コストフォーム実装（cocoon）

- cocoon gem統合
- コスト項目の動的追加・削除
- nested fieldsパーシャル実装
- システムスペック追加

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

git push -u origin feature/p3-04-dynamic-form
```

**PRタイトル**: `Phase 3-04: 動的コストフォーム実装`

---

## PR #5: Stimulus自動計算

### ブランチ作成

```bash
git checkout main
git pull origin main  # PR #4マージ後
git checkout -b feature/p3-05-stimulus-calculator
```

### 実装内容

- ✅ cost-items_controller (Stimulus)
- ✅ コストシート選択で自動入力
- ✅ 金額の自動計算
- ✅ 合計金額のリアルタイム表示

### 実装ファイル

```
app/javascript/controllers/cost_items_controller.js (新規)
app/javascript/controllers/index.js (register)
app/views/medical_records/_form.html.erb (data属性追加)
app/views/medical_records/_cost_item_fields.html.erb (data-action追加)
spec/system/medical_records_spec.rb (更新 - Stimulus動作確認)
```

### テスト実行

```bash
bundle exec rspec spec/system/
bundle exec rubocop -A
rails s  # ブラウザでStimulus動作確認
```

### コミット・PR

```bash
git add .
git commit -m "feat(stimulus): 金額自動計算機能実装

- cost-items_controller実装（Stimulus）
- コストシート選択で自動入力
- 単価・数量変更で小計・合計自動計算
- リアルタイム金額表示

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

git push -u origin feature/p3-05-stimulus-calculator
```

**PRタイトル**: `Phase 3-05: Stimulus金額自動計算実装`

---

## PR #6: Active Storage画像アップロード

### ブランチ作成

```bash
git checkout main
git pull origin main  # PR #5マージ後
git checkout -b feature/p3-06-active-storage
```

### 実装内容

- ✅ Active Storageインストール
- ✅ 画像アップロード機能（最大5枚）
- ✅ 画像バリデーション
- ✅ プレビュー・削除機能

### 実装ファイル

```
db/migrate/*_create_active_storage_*.rb
config/storage.yml
app/models/medical_record.rb (has_many_attached, validations)
app/controllers/medical_records_controller.rb (remove_photo, strong params)
app/views/medical_records/_form.html.erb (画像フィールド)
app/views/medical_records/show.html.erb (画像表示)
spec/models/medical_record_spec.rb (画像テスト)
spec/fixtures/files/sample.jpg (テスト用)
config/routes.rb (remove_photo追加)
```

### セットアップ

```bash
rails active_storage:install
rails db:migrate
mkdir -p spec/fixtures/files
# テスト用画像作成（1x1ピクセル）
```

### テスト実行

```bash
bundle exec rspec spec/models/medical_record_spec.rb
bundle exec rubocop -A
rails s  # 画像アップロード・削除確認
```

### コミット・PR

```bash
git add .
git commit -m "feat(storage): 画像アップロード機能実装

- Active Storage設定
- 画像アップロード（最大5枚、10MB/枚）
- 画像バリデーション（JPEG, PNG）
- プレビュー・削除機能
- テスト完備

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

git push -u origin feature/p3-06-active-storage
```

**PRタイトル**: `Phase 3-06: 画像アップロード機能実装`

---

## PR #7: タグ機能

### ブランチ作成

```bash
git checkout main
git pull origin main  # PR #6マージ後
git checkout -b feature/p3-07-tags
```

### 実装内容

- ✅ Tagモデル
- ✅ MedicalRecordTagモデル（中間テーブル）
- ✅ タグ付け機能
- ✅ カルテへのタグ表示

### 実装ファイル

```
db/migrate/YYYYMMDDHHMMSS_create_tags.rb
db/migrate/YYYYMMDDHHMMSS_create_medical_record_tags.rb
app/models/tag.rb
app/models/medical_record_tag.rb
app/models/medical_record.rb (has_many :tags)
app/models/user.rb (has_many :tags)
app/controllers/medical_records_controller.rb (process_tags)
app/views/medical_records/_form.html.erb (タグ入力)
app/views/medical_records/show.html.erb (タグ表示)
app/views/medical_records/index.html.erb (タグ表示)
spec/models/tag_spec.rb
spec/models/medical_record_tag_spec.rb
spec/factories/tags.rb
```

### テスト実行

```bash
bundle exec rspec spec/models/tag_spec.rb
bundle exec rspec
bundle exec rubocop -A
rails s  # タグ追加・表示確認
```

### コミット・PR

```bash
git add .
git commit -m "feat(tags): タグ機能実装

- Tagモデル実装
- MedicalRecordTagモデル（中間テーブル）
- カルテへのタグ付け機能
- タグ表示（一覧、詳細）
- テスト完備

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

git push -u origin feature/p3-07-tags
```

**PRタイトル**: `Phase 3-07: タグ機能実装`

---

## PR #8: 検索強化 + E2Eテスト（Phase 3完成）

### ブランチ作成

```bash
git checkout main
git pull origin main  # PR #7マージ後
git checkout -b feature/p3-08-search-e2e
```

### 実装内容

- ✅ Ransack統合
- ✅ 高度な検索フォーム
- ✅ フィルタリング機能
- ✅ E2Eテスト（System Spec）
- ✅ Phase 3完了確認

### 実装ファイル

```
Gemfile (ransack確認)
app/controllers/medical_records_controller.rb (ransack)
app/views/medical_records/index.html.erb (検索フォーム)
spec/system/medical_records_spec.rb (E2Eテスト追加)
spec/system/cost_sheets_spec.rb (新規 - E2E)
spec/rails_helper.rb (Capybara設定確認)
```

### テスト実行

```bash
bundle install  # ransack確認
bundle exec rspec  # 全テスト実行
bundle exec rubocop -A
rails s  # 検索機能確認
```

### コミット・PR

```bash
git add .
git commit -m "feat(search): 検索強化 + E2Eテスト実装（Phase 3完成）

- Ransack統合
- 高度な検索フォーム（患者名、施術場所、日付範囲）
- フィルタリング機能
- E2Eテスト完備（System Spec）
- Phase 3全機能の統合テスト成功

Phase 3 完了 ✅

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

git push -u origin feature/p3-08-search-e2e
```

**PRタイトル**: `Phase 3-08: 検索強化 + E2Eテスト実装（Phase 3完成）`

---

## PR作成時のチェックリスト

各PR作成前に以下を確認:

### コード品質
- [ ] テスト全て成功
- [ ] RuboCop 0違反
- [ ] コミットメッセージがConventional Commits形式
- [ ] 不要なコメント・デバッグコード削除

### 動作確認
- [ ] ローカル環境で動作確認
- [ ] ブラウザでUI確認
- [ ] 既存機能に影響なし（回帰テスト）

### AIコードレビュー（必須）
- [ ] Claude CodeでAIコードレビュー実施
- [ ] レビュー結果をPRにコメント投稿
- [ ] **Critical**な問題を全て修正
- [ ] Minorな問題も可能な限り対応
- [ ] 修正後のテストが全て成功

### ドキュメント
- [ ] PR本文に実装内容・テスト結果記載
- [ ] スクリーンショット添付（UI変更がある場合）
- [ ] 次のPR情報記載

### CI/CD
- [ ] GitHub Actions成功確認
- [ ] カバレッジ維持確認

---

## PRマージ後の確認

各PRマージ後:

```bash
# mainブランチを最新に
git checkout main
git pull origin main

# 全テスト実行
bundle exec rspec

# 次のブランチ作成
git checkout -b feature/p3-0X-next-feature
```

---

## トラブルシューティング

### コンフリクト発生時

```bash
# mainを最新に
git checkout main
git pull origin main

# フィーチャーブランチにマージ
git checkout feature/p3-0X-xxx
git merge main

# コンフリクト解決
# ...

git add .
git commit -m "chore: resolve merge conflicts"
git push
```

### テスト失敗時

1. ローカルで全テスト実行
2. 失敗箇所を特定
3. 修正してコミット
4. PRを更新

### CI/CD失敗時

1. GitHub Actionsのログ確認
2. 環境変数・設定ファイル確認
3. ローカルで再現
4. 修正してプッシュ

---

## Phase 3完了基準

PR #8マージ後、以下を確認:

- ✅ 全9つのPRマージ完了
- ✅ 全テスト成功（モデル、リクエスト、システム）
- ✅ RuboCop 0違反
- ✅ CI/CDグリーン
- ✅ ブラウザで全機能動作確認
  - コストシート管理
  - カルテ作成・編集
  - コスト項目動的追加
  - 金額自動計算
  - 画像アップロード
  - タグ付け
  - 検索・フィルタリング

---

## AIコードレビューワークフローについて

### 目的

個人開発プロジェクトですが、コード品質向上とセキュリティ確保のため、Claude Codeによる自動コードレビューを標準プロセスとして導入します。

### メリット

1. **セキュリティ**: 認可漏れ、SQLインジェクション等の重大な問題を早期発見
2. **品質向上**: ベストプラクティス違反や保守性の問題を指摘
3. **学習効果**: レビューコメントから実装パターンを学習
4. **一貫性**: 全PRで同じ基準でレビュー実施

### レビュー基準

- **Critical（必須修正）**:
  - セキュリティ脆弱性
  - 認可・認証の不備
  - データ整合性の問題
  - 重大なバグ

- **Minor（推奨修正）**:
  - コード品質改善
  - ベストプラクティス適用
  - パフォーマンス最適化
  - 保守性向上

### 実施タイミング

1. PR作成直後
2. Criticalな問題を全て修正
3. Minorな問題も可能な限り対応
4. 修正後にCI成功確認
5. PRマージ

---

**Document Version**: 1.1
**Last Updated**: 2025-10-13
**Status**: Ready for Implementation
**Changelog**: AIコードレビューワークフロー追加

このワークフローに従って、Phase 3を8つの小さなPRで段階的に実装してください！
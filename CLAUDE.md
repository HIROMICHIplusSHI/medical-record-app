# 電子カルテアプリ - Claude Code 専用ガイド

**プロジェクト名**: フリーランス美容施術者向け電子カルテアプリ
**対象**: アートメイク施術者（出張型フリーランス）
**開発方針**: TDD・アジャイル・MVP重視
**最終更新**: 2025-10-15

---

## 📋 プロジェクト概要

### 解決する課題

フリーランスのアートメイク施術者が抱える業務課題を解決するWebアプリケーション：

- **コスト入力の手間**: 毎回手動で金額入力 → テンプレート化で効率化
- **請求書作成**: 月末に手動集計 → 自動生成で時間削減
- **売上管理**: 自分で集計・計算 → リアルタイムダッシュボード
- **患者情報管理**: スプレッドシート → 検索性・セキュリティ向上

### 技術スタック

| レイヤー | 技術 |
|---------|------|
| **バックエンド** | Ruby 3.2+, Rails 7.2+ |
| **データベース** | PostgreSQL 14+ |
| **フロントエンド** | Hotwire (Turbo + Stimulus), Tailwind CSS |
| **認証** | Devise |
| **ファイルストレージ** | Active Storage + Cloudflare R2 (S3互換) |
| **PDF生成** | Prawn + prawn-table |
| **テスト** | RSpec + FactoryBot + Capybara + Cuprite |
| **コード品質** | RuboCop + Brakeman + Bullet |

---

## 🎯 開発状況（2025-10-15時点）

### 完了したフェーズ

#### ✅ Phase 1: MVP開発
- 認証機能（Devise + Google OAuth）
- 施術場所管理（CRUD）
- 患者管理（CRUD + 検索・ページネーション）
- コストシート管理（CRUD）
- カルテ管理（CRUD + 動的フォーム + 画像アップロード）
- タグ機能
- 検索・フィルタリング（Ransack）

#### ✅ Phase 2: 拡張機能
- 患者管理拡張（個人情報暗号化）
- 問診票機能（Active Record Encryption）

#### ✅ Phase 3: E2Eテスト・セキュリティ
- System Spec（Cuprite）による包括的なE2Eテスト
- Brakeman によるセキュリティ監査

#### ✅ Phase 4: 完成度向上
- XSS対策（ビューヘルパー）
- CI/CD整備（GitHub Actions）
- コード品質向上（RuboCop）

#### ✅ Phase 5-A: 売上管理ダッシュボード
- 月次・年次売上集計
- 施設別売上表示
- CSV出力機能
- N+1クエリ最適化

### 現在の進捗

**Phase**: Phase 5（拡張機能実装中）
**最新PR**: #15 - Phase 5-A: 売上管理ダッシュボード実装（マージ済み）
**品質スコア**: 90/100
**テスト**: 375 examples, 0 failures
**RuboCop**: 68 files, no offenses

### 次のステップ

**Phase 5-B**: 請求書生成機能（2週間）
- Invoice モデル作成
- 請求書自動生成ロジック
- PDF出力機能（Prawn）
- 日本語フォント対応

---

## 📚 ドキュメント構成

### 必読ドキュメント

| ドキュメント | パス | 用途 |
|-------------|------|------|
| **要件定義書** | `docs/01_requirements.md` | プロジェクト全体像・機能要件 |
| **データモデル設計** | `docs/02_data_model.md` | ER図・テーブル定義 |
| **技術スタック** | `docs/03_technical_stack.md` | 技術選定理由・環境構築 |
| **開発計画** | `docs/04_development_plan.md` | フェーズ別計画・スケジュール |
| **テスト戦略** | `docs/05_testing_strategy.md` | TDD方針・SystemSpec実装 |
| **詳細設計書** | `docs/07_detailed_design.md` | 全モデル・コントローラー仕様 |
| **画面設計書** | `docs/08_screen_design.md` | 全画面のUI仕様 |
| **README** | `docs/README.md` | ドキュメント索引 |

### フェーズ別ドキュメント

```
docs/phases/
├── phase1/ - MVP開発ガイド
├── phase2/ - 患者管理・問診票ガイド
├── phase3/ - カルテ管理・E2Eテストガイド
├── phase4/ - セキュリティ・品質向上ガイド
└── phase5/ - 売上・請求書機能ガイド
    ├── overview.md - Phase 5全体計画
    └── completed/
        └── phase5a_revenue_dashboard.md - Phase 5-A完了報告
```

---

## 🏗️ アーキテクチャ概要

### ディレクトリ構造

```
app/
├── models/              # ビジネスロジック
│   ├── user.rb         # ユーザー（Devise）
│   ├── facility.rb     # 施術場所
│   ├── patient.rb      # 患者（暗号化対応）
│   ├── questionnaire.rb # 問診票（暗号化対応）
│   ├── medical_record.rb # カルテ（売上集計ロジック含む）
│   ├── cost_item.rb    # コスト項目
│   ├── cost_sheet.rb   # コストシートテンプレート
│   └── tag.rb          # タグ
├── controllers/         # リクエスト処理
│   ├── dashboards_controller.rb # 売上ダッシュボード
│   ├── facilities_controller.rb
│   ├── patients_controller.rb
│   ├── questionnaires_controller.rb
│   ├── medical_records_controller.rb
│   ├── cost_sheets_controller.rb
│   └── tags_controller.rb
├── views/               # UI（ERB + Tailwind CSS）
├── javascript/          # Stimulus コントローラー
│   └── controllers/
│       ├── form_controller.js    # 動的フォーム
│       ├── dropdown_controller.js # ドロップダウン
│       └── ...
└── helpers/             # ビューヘルパー

spec/
├── models/              # モデルテスト
├── requests/            # Request Spec（APIテスト）
├── system/              # System Spec（E2Eテスト, Cuprite）
├── factories/           # FactoryBot定義
└── support/             # テストヘルパー
```

### 主要なモデル関連

```ruby
User (施術者)
  has_many :facilities
  has_many :patients
  has_many :medical_records
  has_many :cost_sheets
  has_many :tags

Patient (患者)
  belongs_to :user
  has_one :questionnaire  # 問診票（暗号化）
  has_many :medical_records

Facility (施術場所)
  belongs_to :user
  has_many :medical_records

MedicalRecord (カルテ)
  belongs_to :user
  belongs_to :patient
  belongs_to :facility
  has_many :cost_items
  has_many :tags, through: :medical_record_tags
  has_many_attached :photos

CostItem (コスト項目)
  belongs_to :medical_record
  belongs_to :cost_sheet, optional: true

CostSheet (テンプレート)
  belongs_to :user
  has_many :cost_items
```

---

## 🧪 開発ワークフロー

### TDD開発サイクル（Red-Green-Refactor）

```bash
# 1. ブランチ作成
git checkout -b feature/invoice-generation

# 2. RED: テストを書いて失敗させる
# spec/models/invoice_spec.rb を作成
bundle exec rspec spec/models/invoice_spec.rb  # 失敗を確認

# 3. GREEN: 最小限の実装で成功させる
# app/models/invoice.rb に実装
bundle exec rspec spec/models/invoice_spec.rb  # 成功を確認

# 4. REFACTOR: リファクタリング
# コードを整理・最適化

# 5. 全テスト実行
bundle exec rspec

# 6. RuboCop実行
bundle exec rubocop -A

# 7. コミット
git add .
git commit -m "feat(invoice): add invoice generation feature"

# 8. プッシュ & PR作成
git push origin feature/invoice-generation
gh pr create
```

### PR作成・マージフロー

```bash
# 1. 機能実装完了後
git add -A

# 2. 論理的な単位でコミット分割
git commit -m "feat(model): add Invoice model with validations"
git commit -m "feat(controller): add InvoicesController with CRUD"
git commit -m "feat(view): add invoice list and detail pages"

# 3. プッシュ
git push origin feature/invoice-generation

# 4. PR作成（GitHub CLI）
gh pr create --title "Phase 5-B: 請求書生成機能" --body "$(cat <<'EOF'
## 実装内容
- Invoice モデル作成
- CRUD操作実装
- PDF出力機能

## テスト
- Model Spec: 8件
- Request Spec: 12件
- System Spec: 5件
- カバレッジ: 95%

## チェックリスト
- [x] RSpec 全テストパス
- [x] RuboCop 違反なし
- [x] Brakeman 警告なし
- [x] ドキュメント更新
EOF
)"

# 5. CI完了待ち
# GitHub Actions で RSpec, RuboCop, Brakeman が自動実行

# 6. コードレビュー（必要に応じて）

# 7. マージ
gh pr merge <PR番号> --squash --delete-branch

# 8. main pull
git checkout main
git pull origin main
```

---

## 🎨 コーディング規約

### Ruby/Rails スタイル

- **RuboCop準拠**: `.rubocop.yml` の設定に従う
- **命名規則**: Rails規約（snake_case, CamelCase）
- **コメント**: 日本語OK（わかりやすさ優先）
- **行の長さ**: 120文字以内（`Layout/LineLength: Max: 120`）

### 特殊な設定・例外

```yaml
# .rubocop.yml より抜粋

# OpenStruct使用を許可（PostgreSQL GROUP BY制限の回避）
Style/OpenStructUse:
  Enabled: false

# 長いメソッドの例外
Metrics/MethodLength:
  AllowedMethods:
    - 'questionnaire_params'
    - 'set_date_range'

# テストファイルの例外
Metrics/BlockLength:
  Exclude:
    - 'spec/**/*'
```

### コミットメッセージ規約

**Conventional Commits形式**:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Type**:
- `feat`: 新機能
- `fix`: バグ修正
- `docs`: ドキュメント
- `style`: コードスタイル（機能変更なし）
- `refactor`: リファクタリング
- `test`: テスト追加・修正
- `chore`: ビルド・補助ツール

**例**:
```
feat(invoice): add PDF generation with Prawn

- Implement InvoicePdfGenerator service
- Add Japanese font support (IPAex Gothic)
- Add invoice number auto-generation

Closes #42
```

### 分割コミット規約

**原則**: 1つのPRに複数の論理的な変更がある場合、機能別に分割してコミットする

**分割の指針**:

1. **モデル層の変更**: `feat(model): add Invoice model with validations`
2. **コントローラー層の変更**: `feat(controller): add InvoicesController with CRUD`
3. **ビュー層の変更**: `feat(view): add invoice list and detail pages`
4. **テストの追加**: `test(invoice): add request specs for CRUD operations`
5. **ドキュメント更新**: `docs: update Phase 5-B completion report`

**例（Phase 5-B実装の場合）**:
```bash
git commit -m "feat(model): add Invoice model with validations"
git commit -m "feat(model): add invoice generation logic"
git commit -m "feat(controller): add InvoicesController with CRUD"
git commit -m "feat(view): add invoice list and detail pages"
git commit -m "feat(pdf): add PDF generation with Prawn"
git commit -m "test(invoice): add comprehensive specs"
git commit -m "docs: add Phase 5-B completion report"
```

**メリット**:
- コードレビューが容易（変更単位が明確）
- 変更履歴が理解しやすい
- 問題発生時のロールバックが簡単
- Git履歴の可読性向上
- 原因追跡が効率的（git bisectでピンポイント特定）

**注意点**:
- 各コミットは独立して動作可能な状態であること
- 1つのコミットに複数の責務を含めない
- テストは関連する実装コミットの直後に追加
- ドキュメント更新は最後にまとめてコミット

---

## 🧪 テスト戦略

### テストピラミッド

```
       /\
      /  \  System Spec (E2E)
     /----\  - 主要機能のみ
    /------\  Request Spec (統合)
   /--------\  - コントローラー全般
  /__________\ Model Spec (単体)
                - 全モデル・ロジック
```

### テスト実行コマンド

```bash
# 全テスト実行
bundle exec rspec

# 特定ファイルのテスト
bundle exec rspec spec/models/invoice_spec.rb

# 特定の行のテスト
bundle exec rspec spec/models/invoice_spec.rb:25

# SystemSpec のみ実行（E2E）
bundle exec rspec spec/system/

# カバレッジ計測
COVERAGE=true bundle exec rspec

# 失敗したテストのみ再実行
bundle exec rspec --only-failures
```

### System Spec（E2Eテスト）の書き方

```ruby
# spec/system/invoices_spec.rb
require 'rails_helper'

RSpec.describe 'Invoices', type: :system do
  let(:user) { create(:user) }
  let(:facility) { create(:facility, user: user) }

  before do
    sign_in user
  end

  describe '請求書一覧画面', js: true do
    it '請求書一覧が表示される' do
      create_list(:invoice, 3, user: user, facility: facility)

      visit invoices_path

      expect(page).to have_selector('h1', text: '請求書一覧')
      expect(page).to have_selector('.invoice-item', count: 3)
    end
  end

  describe '請求書作成', js: true do
    it '請求書を作成できる' do
      visit new_invoice_path

      select facility.name, from: '施設'
      fill_in '請求期間（開始）', with: '2024-01-01'
      fill_in '請求期間（終了）', with: '2024-01-31'
      click_button '請求書を作成'

      expect(page).to have_content('請求書を作成しました')
      expect(page).to have_current_path(invoices_path)
    end
  end
end
```

### テスト品質基準

| 指標 | 目標値 | 現在値 |
|------|--------|--------|
| **全体カバレッジ** | 80%以上 | 約95% |
| **Model Spec** | 90%以上 | 100% |
| **Request Spec** | 80%以上 | 100% |
| **System Spec** | 主要機能100% | 100% |

---

## 🔒 セキュリティ対策

### 実装済みの対策

1. **認証・認可**
   - Devise による安全なパスワード管理（bcrypt）
   - `before_action :authenticate_user!` による認証必須化
   - ユーザーごとのデータスコープ分離

2. **個人情報暗号化**
   - Active Record Encryption による患者データ暗号化
   - 問診票データの完全暗号化

3. **XSS対策**
   - ビューヘルパーによるHTMLエスケープ
   - JSON配列のサニタイズ処理

4. **CSRF対策**
   - Rails標準のCSRF保護（authenticity_token）
   - OmniAuth用CSRF保護gem

5. **セキュリティ監査**
   - Brakeman による静的解析（CI組み込み）
   - 定期的な脆弱性チェック

### セキュリティチェック

```bash
# Brakeman実行
bundle exec brakeman

# 依存関係の脆弱性チェック
bundle audit

# RuboCopセキュリティルール
bundle exec rubocop --only Security
```

---

## ⚡ パフォーマンス最適化

### 実装済みの最適化

1. **N+1クエリ対策**
   - `revenue_by_facility`メソッドでのeager loading
   - facilities.nameをSELECT句に含めて1クエリ化

2. **データベース最適化**
   - 適切なインデックス設定
   - Bullet gemによるN+1検出

3. **画像最適化**
   - Active Storage variant機能
   - Cloudflare R2（エグレス無料）

### パフォーマンスチェック

```bash
# Bullet実行（開発環境）
# config/environments/development.rbで有効化済み

# N+1クエリ検出
# ログに Bullet の警告が表示される

# データベースクエリ確認
rails console
> ActiveRecord::Base.logger = Logger.new(STDOUT)
> MedicalRecord.revenue_by_facility(Date.today.beginning_of_month, Date.today.end_of_month)
```

---

## 🚀 デプロイ

### 本番環境（Render）

**URL**: （未デプロイ）
**プラン**: Professional ($7/月〜)
**データベース**: PostgreSQL 14+
**ファイルストレージ**: Cloudflare R2

### 環境変数

```bash
# 必須環境変数
RAILS_ENV=production
RAILS_MASTER_KEY=<config/master.keyの内容>
DATABASE_URL=<RenderのPostgreSQL URL>

# Cloudflare R2
R2_ACCESS_KEY_ID=<R2 Access Key>
R2_SECRET_ACCESS_KEY=<R2 Secret Key>
R2_ENDPOINT=<R2 Endpoint URL>
R2_BUCKET_NAME=<バケット名>

# Google OAuth
GOOGLE_CLIENT_ID=<Client ID>
GOOGLE_CLIENT_SECRET=<Client Secret>
```

### デプロイ手順

```bash
# 1. Renderアカウント作成・PostgreSQL設定

# 2. render.yaml確認
# プロジェクトルートに render.yaml があることを確認

# 3. 環境変数設定
# Renderダッシュボードで環境変数を設定

# 4. GitHubリポジトリ連携
# Renderでリポジトリを連携

# 5. 自動デプロイ
# mainブランチへのプッシュで自動デプロイ

# 6. マイグレーション実行
# bin/render-build.sh で自動実行される

# 7. 動作確認
# https://<your-app>.onrender.com にアクセス
```

---

## 🐛 トラブルシューティング

### よくある問題

#### 1. PostgreSQL接続エラー

```bash
# エラー: FATAL: role "postgres" does not exist

# 解決法:
createuser -s postgres
# または config/database.yml でユーザー名を変更
```

#### 2. Active Storage / ImageMagick エラー

```bash
# エラー: No such file or directory @ rb_sysopen - identify

# 解決法:
brew install imagemagick
# または
brew install vips
```

#### 3. RSpec実行時のSpringエラー

```bash
# エラー: Spring is running in production mode

# 解決法:
bin/spring stop
bundle exec rspec
```

#### 4. テストDB初期化エラー

```bash
# エラー: PG::UndefinedTable

# 解決法:
RAILS_ENV=test rails db:create
RAILS_ENV=test rails db:migrate
```

#### 5. Cuprite / ChromeDriver エラー

```bash
# エラー: Could not find Chrome binary

# 解決法（Mac）:
brew install --cask google-chrome

# 解決法（CI環境）:
# .github/workflows/ci.yml で Chrome をインストール済み
```

---

## 📖 AI開発支援ガイド

### Claude Code との協働

**このドキュメントの目的**:
- Claude Codeがプロジェクトのコンテキストを理解するため
- 開発方針・規約を共有するため
- 効率的な実装支援を受けるため

### Claude Code への指示例

#### 新機能実装

```
「Phase 5-Bの請求書生成機能を実装してください。
docs/phases/phase5/overview.md の Week 8 タスクを参照し、
TDDで実装してください。」
```

#### バグ修正

```
「売上ダッシュボードでN+1クエリが発生しています。
app/models/medical_record.rb の revenue_by_facility メソッドを
最適化してください。」
```

#### テスト追加

```
「InvoiceモデルのRequest Specを追加してください。
CRUD操作と認証のテストをカバーしてください。」
```

#### コードレビュー（エージェント活用）

```
「Phase 5-B のPRをレビューしてください。
実装内容から適切なエージェント（root-cause-analyst等）を選択し、
セキュリティ、パフォーマンス、テストカバレッジを確認してください。」
```

**エージェント選択の指針**:
- **root-cause-analyst**: 複雑な問題分析、アーキテクチャレビュー
- **security-engineer**: セキュリティ監査、脆弱性チェック
- **performance-engineer**: パフォーマンス最適化、N+1クエリ検出
- **quality-engineer**: テストカバレッジ、コード品質評価

実装内容に応じて最適なエージェントを自動選択し、
包括的なセルフレビューを実施します。

### Claude Code が参照すべきドキュメント

**実装前**:
1. `docs/phases/phase5/overview.md` - Phase 5全体計画
2. `docs/02_data_model.md` - データモデル設計
3. `docs/07_detailed_design.md` - 詳細設計

**実装中**:
1. このCLAUDE.md - コーディング規約・ワークフロー
2. `.rubocop.yml` - コードスタイル
3. 関連するspec ファイル - テストパターン

**実装後**:
1. `docs/gap_analysis.md` - 実装状況確認
2. `docs/phases/phase5/completed/` - 完了報告作成

---

## 🎓 学習リソース

### 公式ドキュメント

- **Rails公式ガイド（日本語）**: https://railsguides.jp/
- **Devise**: https://github.com/heartcombo/devise
- **Hotwire**: https://hotwired.dev/
- **Tailwind CSS**: https://tailwindcss.com/docs
- **RSpec**: https://rspec.info/
- **Prawn**: https://prawnpdf.org/docs/

### プロジェクト固有の参考資料

- **TDD実装例**: `docs/phases/phase1/implementation_guide.md`
- **SystemSpec実装例**: `spec/system/`
- **Stimulus実装例**: `app/javascript/controllers/`

---

## 📝 メンテナンス

### 定期的に実行すべきコマンド

```bash
# 依存関係の更新チェック（週次）
bundle outdated

# セキュリティ監査（週次）
bundle audit
bundle exec brakeman

# テストカバレッジ確認（随時）
COVERAGE=true bundle exec rspec
open coverage/index.html

# コード品質チェック（コミット前）
bundle exec rubocop -A
```

### ドキュメント更新ルール

**いつ更新するか**:
- モデル変更時: `02_data_model.md`, `07_detailed_design.md`
- 画面変更時: `08_screen_design.md`
- 機能追加時: 該当フェーズドキュメント
- Phase完了時: `completed/` に完了報告を追加

---

## 📞 サポート・質問

### ドキュメントに関する質問

- **GitHub Issues**: バグ報告・機能要望
- **ドキュメント修正**: Pull Request歓迎

### 開発中の質問

プロジェクト全体のコンテキストを理解するため、以下を参照：

1. **README**: プロジェクト概要
2. **要件定義書**: なぜこの機能が必要か
3. **技術スタック**: なぜこの技術を選んだか
4. **開発計画**: いつ何を実装するか

---

**Last Updated**: 2025-10-15
**Current Phase**: Phase 5（拡張機能実装中）
**Next Milestone**: Phase 5-B（請求書生成機能）

**このドキュメントは、Claude Codeが効率的に開発支援を行うための情報源です。プロジェクトの進捗に応じて継続的に更新してください。**

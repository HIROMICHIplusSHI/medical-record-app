# 電子カルテアプリ（InkFolio）— Claude Code ガイド

フリーランスのアートメイク施術者向け電子カルテ・売上管理アプリ。**個人ポートフォリオ / 技術デモ**。
Rails フルスタック（Hotwire + Tailwind）。開発方針: TDD・MVP 重視。

## 技術スタック

| レイヤー | 技術 |
|---|---|
| 言語 / FW | Ruby 3.2 / Rails 7.2 |
| DB | PostgreSQL 14+ |
| フロント | Hotwire (Turbo + Stimulus) / Tailwind CSS 3.4 / TomSelect |
| 認証 / 認可 | Devise / Pundit |
| 暗号化 | Active Record Encryption (AES-256-GCM) |
| ストレージ | Active Storage + Cloudflare R2 |
| PDF | Prawn + Noto Sans JP |
| テスト / 品質 | RSpec + FactoryBot + Cuprite / RuboCop + Brakeman + Bullet |
| ホスティング | Render（`render.yaml` + [`docs/DEPLOY.md`](docs/DEPLOY.md)）|

## アーキテクチャ

```
app/
├── models/        # 21モデル（下記の主要関連を参照）
├── controllers/   # リソース別 + admin 名前空間
├── policies/      # Pundit 認可ポリシー
├── services/      # PDF生成など（invoice_pdf_generator 等）
├── helpers/       # button_helper（統一ボタンUI）など
├── views/         # ERB + Tailwind
└── javascript/controllers/  # Stimulus（form, dropdown, sortable, signature 等）

spec/  models / requests / system / views / helpers / policies / services
docs/  設計ドキュメント一式（下記参照）
```

### 主要モデル関連

```ruby
User               # 施術者。has_many: facilities, patients, medical_records,
                   #   cost_sheets, invoices, tags。role（admin/user）
Patient            # belongs_to :user。has_one :questionnaire（暗号化）
                   #   has_many :medical_records。個人情報は暗号化
Facility           # belongs_to :user。has_many :medical_records, :invoices
                   #   has_many :facility_doctors
MedicalRecord      # 1来院分の「施術記録」（UI表記=施術記録 / その集合=施術履歴）
                   # belongs_to :user, :patient, :facility
                   #   has_many :cost_items, :invoice_items, :patient_consents
                   #   has_many :tags (through)。has_many_attached :photos
Invoice            # belongs_to :user, :facility。has_many :invoice_items
CostSheet          # コストテンプレ。CostItem が施術記録の明細
ConsentFormTemplate / PatientConsent  # 同意書テンプレ + 電子署名付き作成
Announcement / Inquiry / InvitationCode  # お知らせ / 問い合わせ / 招待コード
```

## 開発ワークフロー（TDD）

Red → Green → Refactor。実装前にブランチを切る（`feature/<slug>`）。

```bash
bundle exec rspec spec/models/xxx_spec.rb   # 単体（先に失敗させる）
bundle exec rspec                            # 全テスト
bundle exec rspec spec/system                # E2E（要 Chrome / Cuprite）
COVERAGE=true bundle exec rspec              # カバレッジ
bundle exec rubocop -A                       # 静的解析 + 自動修正
bundle exec brakeman -q --no-pager           # セキュリティ監査
```

コミット前に **RuboCop 0違反 / Brakeman 警告なし / 全テストパス**を担保する。

> ⚠️ ローカルで `Encoding::CompatibilityError` が出る場合は locale 未設定が原因。
> `export LANG=ja_JP.UTF-8 LC_ALL=ja_JP.UTF-8` で解消（コードの問題ではない）。

## コーディング規約

- **RuboCop 準拠**。行長 120 文字以内。命名は Rails 規約。コメント日本語 OK。
- **イミュータブル志向 / 小さいファイル / エラーは握り潰さず文脈付きで再 throw**。
- ユーザー入力は必ず検証。秘密情報はハードコード禁止（`ENV` 参照、未設定時 throw）。

### ButtonHelper（統一ボタンUI）

すべてのボタンは `app/helpers/button_helper.rb` のヘルパーを使う。`link_to` / `button_to` で
直接スタイルを書かない。

```ruby
show_button "詳細", @patient          # 詳細リンク（茶・塗り）
edit_button "編集", edit_patient_path(@patient)  # 編集（白・枠線）
delete_button "削除", @patient         # 削除（赤・確認ダイアログ付き）
new_button "新規登録", new_patient_path
back_button / cancel_button / search_button / clear_button
# オプション: show_button "詳細", @patient, class: "...", data: { turbo_frame: "modal" }
```

**例外（カスタムスタイル可）**: PDF 生成/DL ボタン（緑）・ステータス変更・ロール切替。

### TomSelect

すべての `select` / `collection_select` / `select_tag` に
`data: { controller: 'tom-select' }` を付与（検索可能ドロップダウンの統一）。
ヘルパー化せず Rails 標準フォームに直接付ける方針（YAGNI・既存コード整合）。例外なし。

## セキュリティ

- 患者個人情報・問診票の健康情報は Active Record Encryption で暗号化。
- 認証 Devise（bcrypt）/ 認可 Pundit（ポリシークラス）。ユーザーごとにデータをスコープ分離。
- XSS: ビューヘルパーでエスケープ。CSRF: Rails 標準。Brakeman を CI 組み込み。
- 本番シークレットは `RAILS_MASTER_KEY` のみ必須（暗号化キーは credentials 内）。R2 キーは画像用で任意。

## ドキュメント

| 種別 | パス |
|---|---|
| ドキュメント索引 | `docs/README.md` |
| 要件定義 / データモデル | `docs/01_requirements.md` / `docs/02_data_model.md` |
| 技術スタック / 詳細設計 | `docs/03_technical_stack.md` / `docs/07_detailed_design.md` |
| 画面設計 / デプロイ | `docs/08_screen_design.md` / `docs/DEPLOY.md` |
| フェーズ別実装記録 | `docs/phases/` |

## トラブルシューティング（抜粋）

- **PostgreSQL 未起動**: `brew services start postgresql@14`（テストは `RAILS_ENV=test rails db:prepare`）
- **Chrome/Cuprite エラー**: `brew install --cask google-chrome`
- **ImageMagick / vips エラー**: `brew install vips`

---

**位置づけ**: 技術デモ・ポートフォリオ（実運用・医療業務での使用は想定しない）

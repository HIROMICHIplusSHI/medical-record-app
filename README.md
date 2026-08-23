# InkFolio — 電子カルテ・売上管理アプリ

フリーランスのアートメイク施術者向けに開発した、電子カルテ・売上管理の Web アプリケーション。
**個人開発のポートフォリオ / 技術デモ**として公開しています。

> **⚠️ 位置づけ**
> 本プロジェクトは技術デモンストレーションおよび個人ポートフォリオです。実際の医療業務での使用や
> 本番運用を目的としたものではありません。詳細は末尾の「免責事項」を参照してください。

## 🎯 プロジェクト概要

従来のスプレッドシート管理による非効率（月末の手作業集計、請求書作成の手間、患者情報の検索性の低さ）を、
Rails フルスタックで解決することを狙った実践プロジェクトです。認証・暗号化・認可・PDF 生成・E2E テストといった
実務で必要になる要素を、最新の Rails 技術スタックで一通り実装しています。

### 主な機能

- **患者管理**: 基本情報・個人情報の暗号化管理（Active Record Encryption）
- **施術記録**: カルテ管理・問診票・同意書（電子署名 + PDF 出力）
- **経営管理**: 売上ダッシュボード・請求書自動生成・PDF 出力・CSV エクスポート
- **権限管理**: 管理者 / 一般ユーザーの分離（Pundit）
- **その他**: お知らせ配信・招待制登録・問い合わせ管理

## 🌐 デモ環境

**URL**: https://medical-record-app-0bpk.onrender.com/

ログイン画面の **「デモアカウントでログイン」ボタン**から、登録・パスワード入力なしで
施術者として全機能をお試しいただけます（データはすべて架空のテストデータです）。

> 管理画面は公開デモの対象外のため、管理者アカウントの資格情報は公開していません。
> 管理機能の画面は下記のスクリーンショット・機能一覧を参照してください。

> **ご注意**: 無料プランで稼働しているため、一定時間アクセスがないとスリープします。
> 初回アクセス時は起動に数十秒かかることがあります。
> デプロイ手順は [`docs/DEPLOY.md`](docs/DEPLOY.md) を参照してください。

## 🛠️ 技術スタック

| レイヤー | 技術 |
|---|---|
| **言語 / FW** | Ruby 3.2 / Rails 7.2 |
| **DB** | PostgreSQL 14+ |
| **フロントエンド** | Hotwire (Turbo + Stimulus) / Tailwind CSS 3.4 / TomSelect |
| **認証 / 認可** | Devise / Pundit |
| **暗号化** | Active Record Encryption (AES-256-GCM) |
| **ストレージ** | Active Storage + Cloudflare R2 (S3 互換) |
| **PDF 生成** | Prawn + Noto Sans JP |
| **テスト** | RSpec + FactoryBot + Capybara + Cuprite |
| **品質 / CI** | RuboCop + Brakeman + Bullet / GitHub Actions |
| **ホスティング** | Render |

## 🔍 技術選定のポイント

実務要件・開発効率・保守性・セキュリティを踏まえた主な判断は以下の通りです。

- **Rails + Hotwire**: この規模では React/Vue は過剰と判断。ビルドパイプライン不要で
  動的フォーム・ドロップダウン・部分更新といった要件を満たせる Hotwire を採用。
- **PostgreSQL**: カルテの柔軟なデータ構造を `jsonb` で扱いつつ、Active Record Encryption と
  組み合わせて個人情報を保護。
- **Cloudflare R2**: 施術写真の配信が多いため、**エグレス無料**が決め手（AWS S3 は $0.09/GB）。
  S3 互換なので Active Storage とそのまま統合。
- **Active Record Encryption**: Rails 7 標準機能。患者の電話番号・メール・住所などを
  透過的に暗号化（gem 追加なし）。
- **Pundit**: ポリシークラスで認可ロジックを一元管理し、`authorize @patient` で宣言的に記述。
- **Prawn**: 日本語 PDF（Noto Sans JP）と複雑な帳票レイアウトを Ruby DSL で細かく制御。

> 各技術の詳細な選定理由・不採用にした選択肢は [`docs/03_technical_stack.md`](docs/03_technical_stack.md) に記載。

## 📊 開発状況・実績

段階的（Phase 1〜7）に実装を積み上げてきました。主な指標:

- **テスト**: Model / Request / View / Policy / Service など非ブラウザ系 **958 examples, 0 failures**
  （別途 System Spec による E2E テストあり）
- **コード品質**: RuboCop **0 offenses** / Brakeman セキュリティ警告 **0**（依存 EOL 通知を除く）
- **規模**: 21 モデル / 8 コントローラ / 73 spec ファイル

実装フェーズの詳細は [`docs/phases/`](docs/phases/) を参照。

## 🚀 ローカルで動かす

### 前提

- Ruby 3.2.9 / PostgreSQL 14+ / Node.js 18+

### セットアップ

```bash
git clone https://github.com/HIROMICHIplusSHI/medical-record-app.git
cd medical-record-app

bundle install

# DB 準備 + デモデータ投入
bin/rails db:create db:migrate db:seed

# サーバー起動（http://localhost:3000）
bin/dev
```

Active Record Encryption のキーは `config/credentials.yml.enc`（`config/master.key` で復号）に
含めています。自分の環境で作り直す場合は `bin/rails db:encryption:init` で生成したキーを
credentials に追加してください。

## 🧪 テスト・品質チェック

```bash
bundle exec rspec              # 全テスト
bundle exec rspec spec/system # E2E（要 Chrome）
COVERAGE=true bundle exec rspec

bundle exec rubocop           # 静的解析
bundle exec brakeman          # セキュリティ監査
```

## 🔐 セキュリティ

- **暗号化**: 患者の個人情報・問診票の健康情報を Active Record Encryption (AES-256-GCM) で保護
- **認証 / 認可**: Devise（bcrypt）+ Pundit によるロールベースアクセス制御
- **XSS / CSRF**: ビューヘルパーによるエスケープ + Rails 標準の CSRF 保護
- **監査**: Brakeman を CI に組み込み

## 📚 ドキュメント

- [ドキュメント索引](docs/README.md)
- [要件定義書](docs/01_requirements.md) / [データモデル設計](docs/02_data_model.md)
- [技術スタック](docs/03_technical_stack.md) / [詳細設計書](docs/07_detailed_design.md)
- [画面設計書](docs/08_screen_design.md)
- [デプロイ手順](docs/DEPLOY.md)

## 📝 ライセンス・免責事項

MIT License

- 本プロジェクトは**技術デモ・ポートフォリオ**であり、実際の医療行為での使用を想定していません。
- 医療法・個人情報保護法等への完全準拠は行っておらず、本番運用には追加対応が必要です。
- 本アプリケーションの使用により生じたいかなる損害についても開発者は責任を負いません。

---

**Purpose**: Technical Demonstration & Portfolio Project

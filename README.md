# InkFolio - 電子カルテアプリ（技術デモ版）

フリーランスアートメイク施術者向けの電子カルテ・売上管理アプリケーション。

> **⚠️ 重要な注意事項**
> 本プロジェクトは**技術デモンストレーション・ポートフォリオ目的**で開発されたものです。
> 医療関連の法規制（医療法、個人情報保護法等）により、実運用は行っておりません。
> あくまで技術的な実装例としてご覧ください。

## 🌐 デモ環境

**URL**: https://medical-record-app-onwc.onrender.com

### デモアカウント

```
管理者アカウント:
  Email: admin@example.com
  Password: AdminDemo2024!

一般ユーザーアカウント:
  Email: user@example.com
  Password: UserDemo2024!
```

> デモ環境のデータは定期的にリセットされる可能性があります。

## 🎯 プロジェクト概要

### 背景

当初はフリーランスアートメイク施術者の業務効率化を目的として開発を開始しましたが、医療関連の法規制（医療法における電子カルテの要件、個人情報保護法の厳格な運用等）により、実運用には高いリスクがあることが判明しました。

そのため、本プロジェクトは**技術的なデモンストレーションおよび個人ポートフォリオ**として位置づけ、以下の技術要素を実装しました。

### デモ内容

- **患者管理**: 個人情報の暗号化（Active Record Encryption）
- **施術記録**: カルテ管理・問診票・同意書（電子署名）
- **経営管理**: 売上ダッシュボード・請求書生成
- **権限管理**: 管理者/一般ユーザーの分離（Pundit）
- **PDF生成**: 請求書・同意書のPDF出力（Prawn）

## ✨ 実装機能

### 患者・施術管理
- **患者管理**: 基本情報・個人情報の暗号化管理
- **問診票**: 健康状態・既往歴・アレルギー情報
- **カルテ**: 施術内容・診断・次回予定の記録
- **同意書**: 電子署名付き同意書の作成・PDF出力

### 経営管理
- **売上ダッシュボード**: 月次・年次売上の可視化、施設別集計
- **請求書管理**: 自動生成・PDF出力・ステータス管理
- **コスト管理**: 施術コストの記録・集計
- **CSV出力**: 売上データのエクスポート

### 管理機能
- **権限管理**: 管理者/一般ユーザーのアクセス制御
- **お知らせ管理**: システムアナウンスの作成・配信
- **ユーザー管理**: ユーザー一覧・ロール変更

### セキュリティ
- **暗号化**: Active Record Encryption（AES-256-GCM）
- **認証**: Devise による安全なパスワード管理
- **認可**: Pundit によるロールベースアクセス制御

## 🛠️ 技術スタック

### フルスタック構成
- **Ruby on Rails フルスタック**: バックエンド + フロントエンド統合開発

### バックエンド
- **Ruby**: 3.2.9
- **Rails**: 7.2.2.2
- **Database**: PostgreSQL 14+
- **認証**: Devise
- **認可**: Pundit
- **暗号化**: Active Record Encryption

### フロントエンド
- **View Template**: ERB（Rails標準）
- **CSS**: Tailwind CSS 3.4
- **JavaScript**: Hotwire (Turbo + Stimulus)
- **UI Components**: TomSelect（検索可能ドロップダウン）

### インフラ
- **ホスティング**: Render
- **ファイルストレージ**: Cloudflare R2（S3互換）
- **PDF生成**: Prawn + Noto Sans JP

### 開発・品質管理
- **Test**: RSpec + FactoryBot + Capybara + Cuprite
- **CI/CD**: GitHub Actions
- **Code Quality**: RuboCop + Brakeman + Bullet

## 📊 開発状況

本プロジェクトは、法規制リスクにより実運用は中止し、**技術デモンストレーション・ポートフォリオ**として公開しています。

### 完了済み機能
- ✅ MVP機能（患者管理・施設管理・カルテ）
- ✅ 問診票・同意書機能（電子署名・PDF出力）
- ✅ 売上管理ダッシュボード
- ✅ 請求書生成・PDF出力
- ✅ 権限管理（管理者/一般ユーザー）
- ✅ お知らせ管理
- ✅ E2Eテスト・セキュリティ監査

### 技術的な成果
- **総コード行数**: 約15,000行
- **テストカバレッジ**: 95%+
- **RSpecテスト数**: 1,029 examples, 1 failure, 23 pending
- **PR数**: 51件
- **コミット数**: 200+

詳細な開発経緯は [docs/phases/](docs/phases/) を参照してください。

## 🚀 ローカル環境セットアップ

### 前提条件
- Ruby 3.2.9
- PostgreSQL 14+
- Node.js 18+

### インストール

```bash
# リポジトリのクローン
git clone https://github.com/HIROMICHIplusSHI/medical-record-app.git
cd medical-record-app

# 依存関係のインストール
bundle install

# データベースのセットアップ
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed  # デモデータの投入

# Active Record Encryption キーの生成
bin/rails db:encryption:init
# 出力されたキーを config/credentials.yml.enc に追加

# サーバーの起動
bin/dev
```

アプリケーションは http://localhost:3000 で起動します。

### 環境変数

本番環境では以下の環境変数が必要です：

```bash
# Active Record Encryption
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=<generated_key>
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=<generated_key>
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=<generated_salt>

# Cloudflare R2
R2_ACCESS_KEY_ID=<your_access_key>
R2_SECRET_ACCESS_KEY=<your_secret_key>
R2_ENDPOINT=<your_endpoint>
R2_BUCKET_NAME=<your_bucket_name>
```

## 🧪 テスト

```bash
# すべてのテストを実行
bundle exec rspec

# 特定のテストを実行
bundle exec rspec spec/models/patient_spec.rb

# System Specのみ実行
bundle exec rspec spec/system/

# カバレッジ計測
COVERAGE=true bundle exec rspec

# コード品質チェック
bundle exec rubocop
bundle exec rubocop -A  # 自動修正

# セキュリティ監査
bundle exec brakeman
```

## 📚 ドキュメント

詳細なドキュメントは [`docs/`](docs/) ディレクトリを参照してください。

### 主要ドキュメント
- [ドキュメント索引](docs/README.md)
- [要件定義書](docs/01_requirements.md)
- [データモデル設計](docs/02_data_model.md)
- [技術スタック](docs/03_technical_stack.md)
- [詳細設計書](docs/07_detailed_design.md)
- [画面設計書](docs/08_screen_design.md)

### 開発ドキュメント
- [Phase 1-4 実装ガイド](docs/phases/)
- [Phase 5 概要](docs/phases/phase5/overview.md)（売上・請求書・同意書）
- [Phase 6 概要](docs/phases/phase6/overview.md)（権限管理）
- [Phase 7-10 計画](docs/phases/)（未実装）

## 🔐 セキュリティ

### 実装済みのセキュリティ対策

- **暗号化**: Active Record Encryption (AES-256-GCM)
  - 患者の個人情報（電話番号、メール、住所、緊急連絡先）
  - 問診票の健康情報

- **認証・認可**:
  - Devise による安全なパスワード管理（bcrypt）
  - Pundit による権限制御（管理者/一般ユーザー）

- **XSS対策**:
  - ビューヘルパーによるHTMLエスケープ

- **CSRF対策**:
  - Rails標準のCSRF保護

- **セキュリティ監査**:
  - Brakeman による静的解析（CI組み込み）

## 📝 ライセンス・免責事項

### ライセンス
MIT License

### 免責事項

本プロジェクトは技術的なデモンストレーション目的で開発されたものです。

- **医療行為への使用禁止**: 本アプリケーションは医療法に基づく電子カルテとしての要件を満たしていません。実際の医療行為・アートメイク施術での使用は行わないでください。

- **個人情報の取り扱い**: デモ環境では個人情報を入力しないでください。暗号化機能は技術デモであり、実運用環境での安全性を保証するものではありません。

- **法的責任**: 本アプリケーションの使用により生じたいかなる損害についても、開発者は責任を負いません。

- **コード品質**: ポートフォリオとして技術要素を示すことを目的としており、商用レベルの完成度を保証するものではありません。

## 🤝 コントリビューション

本プロジェクトは個人のポートフォリオとして公開されています。バグ報告や技術的な質問は Issues でお願いします。

---

**Last Updated**: 2025-10-26
**Status**: Demo Version - Portfolio Project
**Purpose**: Technical Demonstration Only

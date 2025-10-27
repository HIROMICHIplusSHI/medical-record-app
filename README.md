# InkFolio - 電子カルテアプリ（クローズドベータ版）

フリーランスアートメイク施術者向けの電子カルテ・売上管理アプリケーション。

> **⚠️ 重要な注意事項**
> 本プロジェクトは**技術デモンストレーション・ポートフォリオ目的**で開発され、現在**招待制クローズドベータ版**として限定運用中です。
> 医療関連の法規制（医療法、個人情報保護法等）への完全準拠は進行中であり、本番環境での全面運用は行っておりません。
> ご利用にあたっては利用規約とプライバシーポリシーへの同意が必要です。

## 🌐 本番環境

**URL**: https://medical-record-app-onwc.onrender.com

### アクセス方法

本システムは**招待制クローズドベータ版**です。新規登録には招待コードが必要です。

> 評価・テスト目的でのアクセスをご希望の方は、開発者までお問い合わせください。

## 🎯 プロジェクト概要

### 背景

フリーランスアートメイク施術者の業務効率化を目的として開発を開始しました。従来のスプレッドシート管理による非効率性（月末の手作業集計、請求書作成の手間、患者情報の検索性の低さ）を解決し、施術者がより顧客対応に集中できる環境を提供します。

現在は**招待制クローズドベータ版**として限定運用中であり、医療関連法規制（医療法における電子カルテ要件、個人情報保護法の厳格な運用等）への完全準拠を進めながら、実環境でのフィードバック収集と改善を行っています。

同時に、本プロジェクトは**技術デモンストレーションおよび個人ポートフォリオ**としても位置づけられており、最新のRails技術スタックの実践的な活用例を示しています。

### 主な機能

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

## 🔍 技術選定の理由

本プロジェクトの技術スタック選定は、フリーランス施術者の実務要件、開発効率、将来の保守性、セキュリティ要件を総合的に考慮して決定されました。

### Ruby on Rails 7.2
**選定理由**:
- **学習目標との整合**: Railsエコシステム全体の実践的な習得
- **開発生産性**: Convention over Configurationによる迅速なプロトタイピング
- **フルスタック対応**: バックエンド・フロントエンド統合による一貫した開発体験
- **包括的エコシステム**: 認証（Devise）、暗号化（Active Record Encryption）、PDF生成（Prawn）等の成熟したgemライブラリ

### Hotwire (Turbo + Stimulus)
**選定理由**:
- **Rails統合**: Rails 7のデフォルトスタック、シームレスな統合
- **シンプルな構成**: React/Vueに比べてビルドパイプラインが不要、学習コスト低
- **十分な機能性**: 本プロジェクトの要件（動的フォーム、ドロップダウン、リアルタイム更新）に対応可能
- **過去の教訓**: 前プロジェクトでHotwire環境の差異により問題が発生した経験から、System Specによる包括的なE2Eテストを重視

**選定しなかった選択肢**:
- React/Vue: 本プロジェクトの規模では過剰な複雑性、ビルド設定の保守コスト

### PostgreSQL 14+
**選定理由**:
- **本番環境安定性**: Renderの標準データベース、運用実績豊富
- **JSON対応**: カルテの柔軟なデータ構造に対応（`jsonb`カラム）
- **Rails統合**: Active Recordとの親和性が高い
- **暗号化サポート**: Active Record Encryptionとの組み合わせで強固なデータ保護

**選定しなかった選択肢**:
- MySQL: PostgreSQLと比較してJSON性能やRails統合度で劣る
- SQLite: 開発用途のみ、本番環境での並行性・堅牢性が不十分

### Tailwind CSS
**選定理由**:
- **モダンデザイン**: ユーティリティファーストによる柔軟なカスタマイズ
- **開発速度**: クラス名による直感的なスタイリング、CSSファイルの肥大化を防ぐ
- **カスタマイズ性**: InkFolioブランドカラー（greige, ink, accent系）の独自デザインシステム構築

**選定しなかった選択肢**:
- Bootstrap: カスタマイズ性が低い、「Bootstrap感」が出やすい
- CSS-in-JS: Rails環境では設定が煩雑

### Cloudflare R2
**選定理由**:
- **エグレス完全無料**: AWS S3と異なり、画像配信（エグレス）のコストが**完全に無料**（最重要選定理由）
- **S3互換API**: Active Storageとシームレスに統合可能
- **CDN統合**: Cloudflare CDNとの連携による高速配信
- **コスト効率**: 月間10GBストレージまで無料、施術写真の保存に最適

**選定しなかった選択肢**:
- AWS S3: エグレス料金が高額（$0.09/GB）、画像配信が多いアプリには不適
- ローカルストレージ: Renderの無料枠ではディスク永続化不可

### Prawn (PDF生成)
**選定理由**:
- **日本語対応**: Noto Sans JPフォントによる美しい日本語PDF
- **柔軟性**: 請求書・同意書の複雑なレイアウトに対応可能
- **完全なプログラマブル制御**: Ruby DSLによる細かいデザイン調整

**選定しなかった選択肢**:
- Wicked PDF (wkhtmltopdf): HTML→PDFだが日本語フォント設定が煩雑、メンテナンス停滞
- PDFKit: 同上、依存関係の複雑さ

### RSpec + System Spec (Cuprite)
**選定理由**:
- **過去の教訓**: 前プロジェクトでHotwire環境差異により本番環境でバグが発生
- **E2E重視**: System Specによる実ブラウザテスト（Cuprite = Chrome DevTools Protocol）で本番環境と同等の検証
- **包括的テスト**: Model Spec（単体）、Request Spec（統合）、System Spec（E2E）の3層テストピラミッド
- **テストカバレッジ**: 95%+の高カバレッジにより品質保証

### Pundit (認可)
**選定理由**:
- **明確な認可パターン**: ポリシークラスによる権限ロジックの一元管理
- **可読性**: `authorize @patient`のような宣言的な記述
- **保守性**: 権限ルールの変更が容易

**選定しなかった選択肢**:
- CanCanCan: Punditと比較してDSLが複雑、デバッグが困難
- 手動実装: スパゲッティコード化のリスク

### Active Record Encryption
**選定理由**:
- **Rails 7組み込み**: 標準機能として安定性・保守性が高い
- **HIPAA類似要件**: 患者の個人情報（電話番号、メール、住所）を法的要件レベルで保護
- **AES-256-GCM暗号化**: 業界標準の強固な暗号化アルゴリズム
- **透過的な実装**: モデル定義のみで暗号化・復号化が自動化

**選定しなかった選択肢**:
- attr_encrypted gem: Rails 7でActive Record Encryptionが標準化されたため不要
- 手動暗号化: 実装ミスによる脆弱性リスク

### Render (ホスティング)
**選定理由**:
- **シンプルなデプロイ**: GitHubプッシュで自動デプロイ、設定ファイル最小限
- **PostgreSQL統合**: データベースがセットで提供、別途設定不要
- **無料枠**: 個人開発・ポートフォリオに適した無料プラン
- **Rails親和性**: Rails専用のビルド設定（`bin/render-build.sh`）

**選定しなかった選択肢**:
- Heroku: 2022年無料枠廃止、コスト増
- AWS: 設定が複雑、個人開発には過剰

### 技術選定の総合評価

本プロジェクトの技術スタックは、以下の観点でバランスの取れた構成となっています：

- ✅ **開発効率**: Rails + Hotwireによる迅速なプロトタイピング
- ✅ **コスト効率**: Cloudflare R2（エグレス無料）+ Render無料枠
- ✅ **セキュリティ**: Active Record Encryption + Pundit + Brakeman監査
- ✅ **保守性**: 成熟したエコシステム、豊富なドキュメント
- ✅ **学習価値**: 最新Rails技術スタックの実践的な活用例

## 📊 開発状況

本プロジェクトは現在**招待制クローズドベータ版**として限定運用中です。医療法・個人情報保護法への完全準拠を進めながら、実環境でのフィードバック収集と改善を継続的に行っています。

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

本プロジェクトは招待制クローズドベータ版として限定運用中です。

- **医療法・個人情報保護法準拠**: 本アプリケーションは医療法に基づく電子カルテ要件および個人情報保護法への完全準拠を目指していますが、現在はクローズドベータ版であり、法規制への完全対応は進行中です。実際の医療行為での使用は招待されたベータテスターのみに限定されます。

- **個人情報の取り扱い**: 利用者は利用規約とプライバシーポリシーに同意の上、顧客から適切な同意を取得した上で個人情報を入力する責任を負います。暗号化機能（Active Record Encryption AES-256-GCM）は業界標準の保護を提供しますが、完全な安全性を保証するものではありません。

- **法的責任**: 本アプリケーションの使用により生じたいかなる損害についても、開発者は責任を負いません。利用者は自己責任で使用するものとします。

- **コード品質**: 本プロジェクトは技術デモンストレーション・ポートフォリオとしても位置づけられており、最新のRails技術スタックの実践的な活用例を示していますが、商用レベルの完全な完成度を保証するものではありません。

## 🤝 コントリビューション

本プロジェクトは個人のポートフォリオとして公開されています。バグ報告や技術的な質問は Issues でお願いします。

---

**Last Updated**: 2025-10-27
**Status**: Closed Beta - Limited Operation
**Purpose**: Technical Demonstration & Portfolio Project (Invitation-only Beta Testing)

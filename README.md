# フリーランス美容施術者向け電子カルテアプリ

フリーランスの美容施術者（アートメイク、美容医療等）が、複数の施術場所での患者管理・カルテ記録・請求書発行を一元管理できるWebアプリケーションです。

## 🎯 プロジェクト概要

- **目的**: フリーランス美容施術者の業務効率化
- **ユーザー**: 複数の施設で施術を行う個人事業主
- **主な機能**: 患者管理、施術記録（カルテ）、問診票、同意書、請求書発行

## 📋 実装状況

### ✅ Phase 1: 施設管理（完了）
- 施設のCRUD操作
- ユーザーごとの施設管理
- CI/CD（GitHub Actions + RuboCop + RSpec）

### 🚧 Phase 2: 患者管理 + 問診票（次フェーズ）
- 患者の基本情報管理（暗号化）
- 問診票機能

## 🛠️ 技術スタック

- **Ruby**: 3.2.9
- **Rails**: 7.1.5.2
- **Database**: PostgreSQL 14
- **認証**: Devise + Google OAuth 2.0
- **CSS**: Tailwind CSS 3.4
- **JavaScript**: Hotwire (Turbo + Stimulus)
- **Test**: RSpec + FactoryBot
- **CI/CD**: GitHub Actions

## 🚀 セットアップ

```bash
# 依存関係のインストール
bundle install

# データベースのセットアップ
bin/rails db:create
bin/rails db:migrate

# サーバーの起動
bin/dev
```

アプリケーションは http://localhost:3333 で起動します。

## 🧪 テスト

```bash
# すべてのテストを実行
bundle exec rspec

# コード品質チェック
bundle exec rubocop
```

## 📚 ドキュメント

詳細なドキュメントは [`docs/`](docs/) ディレクトリを参照してください。

### 主要ドキュメント
- [ドキュメント索引](docs/README.md) - すべてのドキュメントへの入り口
- [要件定義書](docs/01_requirements.md)
- [データモデル設計](docs/02_data_model.md)
- [セキュリティ仕様](docs/security.md)
- [Phase 1 実装ガイド](docs/phases/phase1/implementation_guide.md)
- [Phase 2 実装ガイド](docs/phases/phase2/implementation_guide.md)

## 🔐 セキュリティ

- **暗号化**: Active Record Encryption (AES-256-GCM)
- **認証**: Devise + OAuth 2.0
- **HTTPS**: 本番環境で強制

詳細: [docs/security.md](docs/security.md)

## 📊 現在の実装状況

- ✅ Phase 1: 施設管理（完了）
- 🚧 Phase 2: 患者管理 + 問診票（ドキュメント作成完了）
- ⏳ Phase 3: カルテ管理
- ⏳ Phase 4: 同意書 + 電子署名
- ⏳ Phase 5: 請求書発行

## 🏷️ バージョン

- **Phase 1**: `v1.0-p1-facility` - 施設管理機能

## 📝 開発ワークフロー

```
main
  └─ feature/p1-facility  ← Phase 1（マージ済み）
  └─ feature/p2-patient   ← Phase 2（次に実装）
```

詳細は [docs/README.md](docs/README.md) を参照してください。

---

**Last Updated**: 2025-10-12
**Version**: 1.0 (Phase 1 Complete)

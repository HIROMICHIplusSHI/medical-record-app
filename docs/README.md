# ドキュメント索引

**プロジェクト名**: フリーランス美容施術者向け電子カルテアプリ
**最終更新**: 2025-10-12

---

## 📚 ドキュメント構成

このディレクトリには、プロジェクトのすべての設計・開発ドキュメントが含まれています。

### 基本ドキュメント（01-09）

プロジェクト全体に関わる基本的なドキュメントです。実装前に一読することを推奨します。

| # | ドキュメント名 | 説明 | サイズ |
|---|---------------|------|--------|
| 01 | [要件定義書](./01_requirements.md) | プロジェクト概要、機能要件、非機能要件 | 15KB |
| 02 | [データモデル設計](./02_data_model.md) | ER図、テーブル定義、リレーションシップ | 23KB |
| 03 | [技術スタック](./03_technical_stack.md) | 技術選定、開発環境セットアップ | 22KB |
| 04 | [開発計画](./04_development_plan.md) | フェーズ別開発計画、マイルストーン | 24KB |
| 05 | [テスト戦略](./05_testing_strategy.md) | テストピラミッド、SystemSpec実装 | 24KB |
| 06 | [Cloudflare R2セットアップ](./06_cloudflare_r2_setup.md) | 画像ストレージ設定ガイド | 12KB |
| 07 | [詳細設計書](./07_detailed_design.md) | 全モデル・コントローラーの実装仕様 | 40KB |
| 08 | [画面設計書](./08_screen_design.md) | 全画面のワイヤーフレームとUI仕様 | 22KB |
| 09 | [ドキュメント自動化](./09_document_automation.md) | Git Hooks、CHANGELOG生成 | 8KB |

### フェーズ別実装ガイド（phases/）

各開発フェーズの詳細な実装手順です。TDD実装フローと具体的なコード例が含まれます。

```
phases/
├── phase1/                        # Phase 1: MVP開発
│   └── implementation_guide.md    # 実装ガイド（28KB）
│
├── phase2/                        # Phase 2: 拡張機能（Phase 1完了後に作成）
├── phase3/                        # Phase 3: 改善・最適化
└── phase4/                        # Phase 4: デプロイ・運用
```

#### Phase 1: MVP開発（Week 3-6）

| ドキュメント | 説明 | ステータス |
|-------------|------|----------|
| [実装ガイド](./phases/phase1/implementation_guide.md) | TDD実装手順、コード例、トラブルシューティング | ✅ 完成 |

**Phase 1の成果物:**
- ✅ 施術場所管理（CRUD）
- ✅ 患者管理（CRUD + 検索）
- ✅ コストシート管理（CRUD）
- ✅ カルテ管理（CRUD + 動的フォーム + 画像アップロード）
- ✅ タグ機能
- ✅ 検索・フィルタリング

#### Phase 2: 拡張機能（未作成）

Phase 1完了後に作成予定

**Phase 2の予定機能:**
- 請求書管理（CRUD + PDF生成）
- 売上ダッシュボード
- 月次・年次売上分析
- CSV エクスポート

#### Phase 3: 改善・最適化（未作成）

Phase 2完了後に作成予定

#### Phase 4: デプロイ・運用（未作成）

Phase 3完了後に作成予定

---

## 🎯 読む順序の推奨

### 1. プロジェクト理解（初回）

1. [要件定義書](./01_requirements.md) - プロジェクトの全体像を把握
2. [データモデル設計](./02_data_model.md) - データ構造の理解
3. [技術スタック](./03_technical_stack.md) - 使用技術の確認

### 2. 開発準備

4. [開発計画](./04_development_plan.md) - 開発スケジュールの確認
5. [テスト戦略](./05_testing_strategy.md) - TDDの方針理解
6. [Cloudflare R2セットアップ](./06_cloudflare_r2_setup.md) - 環境設定

### 3. 実装（Phase 1）

7. [詳細設計書](./07_detailed_design.md) - 実装仕様の確認
8. [画面設計書](./08_screen_design.md) - UI仕様の確認
9. [Phase 1実装ガイド](./phases/phase1/implementation_guide.md) - 実装手順に従う

### 4. 保守

10. [ドキュメント自動化](./09_document_automation.md) - ドキュメント更新ルールの理解

---

## 📖 ドキュメントの使い方

### 開発者（自分自身）向け

**実装中:**
- Phase実装ガイドを参照しながらTDDで実装
- 詳細設計書で仕様を確認
- 画面設計書でUIを実装

**デバッグ中:**
- テスト戦略ドキュメントでデバッグ方法を確認
- Phase実装ガイドのトラブルシューティングを参照

**機能追加時:**
- 詳細設計書を更新
- 画面設計書を更新（UI変更の場合）
- ドキュメント自動化ガイドに従ってバージョン管理

### レビュアー向け

**コードレビュー時:**
1. 詳細設計書と実装の一致を確認
2. 画面設計書とUIの一致を確認
3. テストカバレッジの確認

**設計レビュー時:**
1. データモデル設計の妥当性確認
2. 詳細設計書の実装可能性確認
3. 画面設計書のユーザビリティ確認

---

## 🔄 ドキュメント更新ルール

### いつ更新するか

- **モデル変更時**: 02_data_model.md、07_detailed_design.md
- **画面変更時**: 08_screen_design.md
- **機能追加時**: 該当するすべてのドキュメント
- **Phase完了時**: README.md のステータス更新

### 更新方法

```bash
# 1. コードとドキュメントを同時に更新
git add app/models/facility.rb docs/07_detailed_design.md

# 2. ドキュメントバージョンを更新
./scripts/update_doc_version.sh docs/07_detailed_design.md 1.1 "Add revenue calculation method"

# 3. コミット（Conventional Commits形式）
git commit -m "feat(facility): add revenue calculation method

- Implement total_revenue method with date range
- Update detailed design document to v1.1"
```

詳細は [ドキュメント自動化ガイド](./09_document_automation.md) を参照。

---

## 📊 ドキュメント一覧（バージョン情報）

| ドキュメント | バージョン | 最終更新 | 次回レビュー |
|-------------|-----------|---------|-------------|
| 01_requirements.md | 1.0 | 2025-10-12 | Phase 1完了時 |
| 02_data_model.md | 1.0 | 2025-10-12 | Phase 1完了時 |
| 03_technical_stack.md | 1.0 | 2025-10-12 | Phase 1完了時 |
| 04_development_plan.md | 1.0 | 2025-10-12 | Phase 1完了時 |
| 05_testing_strategy.md | 1.0 | 2025-10-12 | Phase 1完了時 |
| 06_cloudflare_r2_setup.md | 1.0 | 2025-10-12 | 本番運用開始時 |
| 07_detailed_design.md | 1.0 | 2025-10-12 | Phase 1実装開始時 |
| 08_screen_design.md | 1.0 | 2025-10-12 | Phase 1実装開始時 |
| 09_document_automation.md | 1.0 | 2025-10-12 | Phase 1実装開始時 |
| phases/phase1/implementation_guide.md | 1.0 | 2025-10-12 | Phase 1実装開始時 |

---

## 🚀 クイックスタート

Phase 1の実装を開始する場合：

```bash
# 1. ドキュメントを読む
open docs/phases/phase1/implementation_guide.md

# 2. 環境確認
ruby -v
rails -v
psql --version

# 3. ブランチ作成
git checkout -b feature/phase1-setup

# 4. 実装開始！
# Phase 1実装ガイドの「3.1 Day 1-2: Facility実装」から開始
```

---

## 📞 質問・フィードバック

ドキュメントに関する質問や改善提案がある場合：

- GitHub Issues で報告
- または直接ドキュメントを修正してPull Request

---

**Last Updated**: 2025-10-12

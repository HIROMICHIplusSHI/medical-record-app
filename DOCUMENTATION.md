# プロジェクトドキュメント構造ガイド

**最終更新**: 2025-10-29
**目的**: プロジェクト内の2つのドキュメントディレクトリの役割と使い分けを明確化

---

## 📁 ドキュメントディレクトリの概要

このプロジェクトには、**2つの独立したドキュメントディレクトリ**が存在します：

1. **`docs/`** - プロジェクト公式ドキュメント（Git管理、永続的）
2. **`claudedocs/`** - AI開発支援ドキュメント（Git管理、一時的・分析用）

---

## 📚 `docs/` - プロジェクト公式ドキュメント

### 目的
- プロジェクトの正式な技術ドキュメント
- 開発者・ユーザー向けの永続的な情報源
- プロジェクトの全体像・設計・仕様を記録

### 対象読者
- 開発者（現在・未来）
- プロジェクト管理者
- ステークホルダー
- 新規参加メンバー

### ドキュメント種類

#### 基礎ドキュメント（トップレベル）
| ファイル | 内容 | 更新頻度 |
|---------|------|---------|
| `01_requirements.md` | 要件定義書（機能要件・非機能要件） | フェーズごと |
| `02_data_model.md` | データモデル設計（ER図・テーブル定義） | モデル追加時 |
| `03_technical_stack.md` | 技術スタック（選定理由・環境構築） | 技術変更時 |
| `04_development_plan.md` | 開発計画（フェーズ別スケジュール） | 計画見直し時 |
| `05_testing_strategy.md` | テスト戦略（TDD方針・カバレッジ） | テスト方針変更時 |
| `06_cloudflare_r2_setup.md` | Cloudflare R2設定（ファイルストレージ） | インフラ変更時 |
| `07_detailed_design.md` | 詳細設計（全モデル・コントローラー仕様） | 実装完了時 |
| `08_screen_design.md` | 画面設計（全画面のUI仕様） | UI変更時 |
| `09_document_automation.md` | ドキュメント自動化（自動生成ルール） | ドキュメント方針変更時 |
| `README.md` | ドキュメント索引（全ドキュメント一覧） | ドキュメント追加時 |
| `gap_analysis.md` | ギャップ分析（計画 vs 実装状況） | フェーズ完了時 |
| `security.md` | セキュリティ対策（脆弱性対策・監査） | セキュリティ変更時 |

#### フェーズ別ドキュメント（`docs/phases/`）
```
docs/phases/
├── phase1/          # MVP開発ガイド
├── phase2/          # 患者管理・問診票ガイド
├── phase3/          # カルテ管理・E2Eテストガイド
├── phase4/          # セキュリティ・品質向上ガイド
├── phase5/          # 売上・請求書・同意書機能ガイド
│   ├── overview.md
│   └── completed/
│       ├── phase5a_revenue_dashboard.md
│       ├── phase5b_invoice_management.md
│       └── ...
├── phase6/          # 権限管理・お知らせ・お問い合わせ
│   ├── overview.md
│   └── completed/
│       ├── phase6a_rbac_announcements.md
│       ├── phase6b_inquiry_system.md
│       └── ...
└── phase7/          # 招待コード機能・認証強化
    ├── README.md    # Phase 7概要
    └── completed/
        └── phase7_completion_report.md
```

#### その他ドキュメント
- `beta_tos.md` / `privacy_policy.md` - 本番利用規約・プライバシーポリシー
- `demo_terms.md` / `demo_privacy_policy.md` - デモ版利用規約（削除候補）
- `ai_code_review_guide.md` - AIレビューガイドライン

### 管理ルール
- **Git管理**: ✅ すべてコミット対象
- **更新タイミング**: フェーズ完了時・仕様変更時・設計変更時
- **削除ルール**: 古くなったドキュメントは削除せず、`archived/`に移動
- **命名規則**: `snake_case.md`、フェーズ番号を含む（例: `phase5a_revenue_dashboard.md`）

---

## 🔍 `claudedocs/` - AI開発支援ドキュメント

### 目的
- Claude Codeによるコードレビュー結果の保存
- 品質分析・パフォーマンス分析の記録
- 問題分析・根本原因分析の履歴
- 一時的な調査・実験結果の記録

### 対象読者
- Claude Code（AI開発支援）
- 開発者（品質確認・問題追跡）

### ドキュメント種類

#### コードレビュー（主要）
| ファイル | 内容 | 作成タイミング |
|---------|------|--------------|
| `code_review_phase5_b_2_invoices.md` | Phase 5-B-2請求書機能レビュー | PR作成前 |
| `phase7_comprehensive_review.md` | Phase 7包括レビュー | フェーズ完了時 |
| `phase7_invitation_security_review.md` | セキュリティ専門レビュー | セキュリティ実装時 |
| `phase7_quality_review.md` | 品質エンジニアレビュー | 品質チェック時 |
| `phase7_test_quality_review.md` | テスト品質レビュー | テスト追加時 |
| `phase7_backend_architecture_review.md` | バックエンド設計レビュー | アーキテクチャ変更時 |

#### 問題分析
| ファイル | 内容 | 作成タイミング |
|---------|------|--------------|
| `root_cause_analysis_pr8.md` | PR #8根本原因分析 | 問題発生時 |
| `phase5b1_code_review_and_fixes.md` | Phase 5-B-1修正記録 | バグ修正時 |

#### パフォーマンス分析
```
claudedocs/performance_reviews/
├── phase6_performance_analysis.md
└── ...
```

#### その他
| ファイル | 内容 | 作成タイミング |
|---------|------|--------------|
| `invitation_code_implementation_plan.md` | 招待コード実装計画 | 実装前計画 |
| `phase5_b_2_invoice_management.md` | 請求書管理機能概要 | 実装完了時 |
| `pr44_performance_review.md` | PR #44パフォーマンスレビュー | PR作成前 |

### 管理ルール
- **Git管理**: ✅ コミット対象（分析履歴として有用）
- **更新タイミング**: レビュー実施時・問題分析時・品質チェック時
- **削除ルール**: 参照価値がなくなった場合のみ削除（基本的に保持）
- **命名規則**: `snake_case.md`、レビュー対象を明示（例: `phase7_security_review.md`）
- **一時性**: プロジェクト終了後、不要なレビューは削除可能

---

## 🔄 ドキュメント管理のベストプラクティス

### 1. 新しいドキュメントを作成するとき

**公式ドキュメント（`docs/`）を作成する場合**:
- プロジェクトの永続的な情報源となるか？
- 開発者全員が参照すべき内容か？
- 将来のメンテナンスで必要になるか？

**AI支援ドキュメント（`claudedocs/`）を作成する場合**:
- Claude Codeのレビュー結果か？
- 一時的な調査・分析結果か？
- 品質チェック・問題追跡の記録か？

### 2. ドキュメントの更新頻度

**`docs/`（低頻度、高品質）**:
- フェーズ完了時
- 仕様変更時
- 設計変更時
- 重要な技術的決定時

**`claudedocs/`（高頻度、分析重視）**:
- PR作成前のレビュー
- 問題発生時の調査
- 品質チェック実施時
- パフォーマンス分析時

### 3. ドキュメントの削除・アーカイブ

**`docs/`**:
- ❌ 削除しない（歴史的価値があるため）
- ✅ 古いドキュメントは `docs/archived/` に移動
- ✅ README.mdで「Deprecated」マークを明示

**`claudedocs/`**:
- ✅ プロジェクト終了後、参照価値のないレビューは削除可能
- ✅ 重要な分析結果（根本原因分析など）は保持推奨
- ⚠️ 削除前に `docs/` に重要な知見を転記

### 4. ドキュメントのリンク

**`docs/` から `claudedocs/` へのリンク**:
- ❌ 基本的にリンクしない（`docs/`は自己完結）
- ✅ 例外: 詳細な分析結果を参照する場合のみ

**`claudedocs/` から `docs/` へのリンク**:
- ✅ 自由にリンク可能（公式仕様を参照）

### 5. コミットメッセージの規約

**`docs/` の変更**:
```
docs(phase7): Phase 7完了報告書を追加
docs(gap_analysis): Phase 7完了状態に更新
docs(requirements): ユーザー管理機能要件を追加
```

**`claudedocs/` の変更**:
```
docs(review): Phase 7セキュリティレビュー結果を追加
docs(analysis): PR #57根本原因分析を追加
chore(docs): 古いレビューをアーカイブ
```

---

## 📊 現在のドキュメント状態（2025-10-29）

### `docs/`（20ファイル）
- ✅ 基礎ドキュメント完備
- ✅ Phase 1〜7のドキュメント整備済み
- ✅ gap_analysis.md最新（2025-10-29更新）
- ⚠️ Phase 8以降のドキュメント未作成

### `claudedocs/`（18ファイル）
- ✅ Phase 5〜7のレビュー結果保存
- ✅ パフォーマンスレビューディレクトリ整備
- ✅ 根本原因分析保存
- ⚠️ 古いデモ版ドキュメント整理候補（`demo_*.md`）

---

## 🚀 次のステップ

### Phase 8以降の計画
1. **`docs/phases/phase8/`** 作成
   - overview.md
   - completed/ ディレクトリ準備

2. **`gap_analysis.md`** の継続更新
   - Phase 8開始時に最新状況を反映

3. **`claudedocs/`** の定期整理
   - 参照価値のないレビューの削除
   - 重要な知見の `docs/` への転記

---

## 📝 FAQ

### Q1: 新しい機能のドキュメントはどこに書く？
**A**: `docs/phases/phaseX/` に作成します。実装前は計画書（overview.md）、実装後は完了報告書（`completed/phaseX_Y_feature.md`）。

### Q2: Claude Codeのレビュー結果はどこに保存？
**A**: `claudedocs/` に保存します。命名は `phaseX_Y_review_type.md`（例: `phase7_security_review.md`）。

### Q3: 古いドキュメントはどうすればいい？
**A**: `docs/` は削除せずアーカイブ。`claudedocs/` は参照価値がなければ削除可能。

### Q4: ドキュメントの更新タイミングは？
**A**: `docs/`はフェーズ完了時・仕様変更時。`claudedocs/`はレビュー実施時・問題分析時。

### Q5: どちらに書くか迷ったら？
**A**: 迷ったら`docs/`。永続的な情報は公式ドキュメントに。一時的な分析は`claudedocs/`。

---

**作成者**: Claude
**最終更新**: 2025-10-29
**バージョン**: 1.0

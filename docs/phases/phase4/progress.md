# Phase 4 進捗管理

**バージョン**: 1.0
**最終更新**: 2025-10-13
**現在のステータス**: 🔄 進行中

---

## 概要

Phase 4では、**UI/UX改善・統合**を目標とし、実用的なアプリケーションとしての完成度を高めます。

**主な目標**:
- 統一されたナビゲーション実装
- iPad最適化（メインペルソナ向け）
- レスポンシブ対応（スマートフォン対応）
- ユーザビリティ向上

---

## Phase 4-01: ヘッダー・ナビゲーション

### ステータス
🔄 **進行中** - ブランチ作成・ドキュメント整備完了

### PR情報
- **PR番号**: TBD
- **ブランチ**: `feature/p4-01-header-navigation`
- **作成日**: 2025-10-13
- **担当**: Claude Code + ユーザー
- **レビュー**: TBD
- **マージ日**: TBD

### 実装内容

#### 目標
全画面で共通のヘッダーを実装し、ナビゲーション体験を向上させる。

#### 実装範囲
- [x] ブランチ作成 (`feature/p4-01-header-navigation`)
- [x] Phase 4ドキュメント整備
  - [x] `docs/phases/phase4/overview.md` 作成
  - [x] `docs/phases/phase4/workflow.md` 作成
  - [x] `docs/phases/phase4/progress.md` 作成（本ファイル）
- [ ] ヘッダーコンポーネント実装
  - [ ] `app/views/shared/_header.html.erb` 作成
  - [ ] デスクトップナビゲーション
  - [ ] モバイルハンバーガーメニュー（Stimulus.js）
  - [ ] ユーザードロップダウンメニュー（Stimulus.js）
  - [ ] 現在ページのハイライト表示
- [ ] レイアウト統合
  - [ ] `app/views/layouts/application.html.erb` 更新
- [ ] Stimulusコントローラー実装
  - [ ] `app/javascript/controllers/header_controller.js`
  - [ ] `app/javascript/controllers/dropdown_controller.js`
- [ ] Systemテスト作成
  - [ ] `spec/system/header_navigation_spec.rb`
- [ ] iPad/Safari実機テスト
- [ ] iPhone/Safari実機テスト
- [ ] PR作成・レビュー・マージ

#### デザイン仕様

**ヘッダー**:
```
高さ: 64px
背景色: bg-blue-600 (Tailwind)
テキスト色: text-white
レスポンシブ: モバイル（< 768px）でハンバーガーメニュー
```

**メニュー項目**:
- ダッシュボード → `/`
- カルテ → `/medical_records`
- 患者 → `/patients`
- 施術場所 → `/facilities`
- コストシート → `/cost_sheets`
- 請求書 → `#` (ダミーリンク)

**ユーザーメニュー**:
- マイアカウント → `#` (ダミーリンク)
- ログアウト → `/users/sign_out`

#### 技術スタック
- **フロントエンド**: Stimulus.js, Tailwind CSS
- **バックエンド**: Rails 7.1 (ERBテンプレート)
- **テスト**: RSpec (System spec)

#### 実装メモ

**2025-10-13**:
- ブランチ `feature/p4-01-header-navigation` 作成
- Phase 4ドキュメント整備完了:
  - `overview.md`: Phase 4全体の位置づけ・スコープ定義
  - `workflow.md`: ブランチ戦略、PRプロセス、CI/CD設定
  - `progress.md`: 本ファイル、進捗管理用

**次のステップ**:
1. ユーザー確認: ドキュメント内容のレビュー
2. ヘッダーコンポーネント実装開始（TDD）
3. デスクトップナビゲーション実装
4. モバイルハンバーガーメニュー実装

#### 参考資料
- デザイン仕様: `docs/08_screen_design.md` (lines 83-100)
- Phase 3 Tom Select実装: `docs/phases/phase3/progress.md` (Phase 3-04)
- 既存Stimulusコントローラー: `app/javascript/controllers/cost_items_controller.js`

---

## Phase 4-02: 問診票チェックボックスUI改善（予定）

### ステータス
⏳ **未着手** - Phase 4-01完了後に着手

### 背景
Phase 2で実装済みの問診票チェックボックスUI（`_form_checkbox.html.erb`）が `USE_CHECKBOX_UI = false` フラグで無効化されたまま放置されていた機能の回収。Phase 3で実装されたカルテ機能との連携調整が必要。

### 実装予定内容
- `USE_CHECKBOX_UI` フラグを `false` → `true` に変更
- 現在のカルテ機能との連携確認・調整
- iPad/Safariでのタッチ操作性確認
- 既存データとの後方互換性確認
- Systemテスト実行（既存テスト活用）

### 見積もり
- 実装時間: 1-2時間（フラグ変更 + 動作確認 + 調整）
- 優先度: 🟡 中

### 参考資料
- Phase 3計画: `docs/phases/phase3/pr_workflow.md` (PR #2.5)
- チェックボックスフォーム: `app/views/questionnaires/_form_checkbox.html.erb`
- コントローラー: `app/controllers/questionnaires_controller.rb` (line 7)

---

## Phase 4-03: マイアカウント画面（予定）

### ステータス
⏳ **未着手**

### 実装予定内容
- マイアカウント画面作成
- プロフィール編集機能
- パスワード変更機能
- アカウント設定

### 見積もり
- 実装時間: 4-6時間
- 優先度: 🟡 中

---

## Phase 4-04: ダッシュボード改善（予定）

### ステータス
⏳ **未着手**

### 実装予定内容
- 最近のアクティビティ表示
- クイックアクセスリンク
- 統計情報の可視化

### 見積もり
- 実装時間: 6-8時間
- 優先度: 🟢 低

---

## マイルストーン

### Milestone 4.1: ナビゲーション実装（目標: 2025-10-14）

- [x] Phase 4ドキュメント整備
- [x] ブランチ作成
- [ ] ヘッダーコンポーネント実装
- [ ] Systemテスト作成
- [ ] 実機テスト（iPad/iPhone）
- [ ] PR #10 マージ

**進捗率**: 30% (2/6 完了)

### Milestone 4.2: 問診票UI改善（目標: 2025-10-15）

- [ ] `USE_CHECKBOX_UI` フラグ変更
- [ ] カルテ連携確認・調整
- [ ] iPad/Safari動作確認
- [ ] PR マージ

**進捗率**: 0% (0/4 完了)

### Milestone 4.3: マイアカウント実装（目標: TBD）

- [ ] マイアカウント画面作成
- [ ] プロフィール編集機能
- [ ] パスワード変更機能
- [ ] PR マージ

**進捗率**: 0% (0/4 完了)

---

## 品質指標

### テストカバレッジ

| 対象 | 目標 | 現在 | ステータス |
|------|------|------|-----------|
| **全体** | 80%以上 | 91.03% | ✅ 達成 |
| **Models** | 100% | 100% | ✅ 達成 |
| **Controllers** | 90%以上 | 100% | ✅ 達成 |
| **Helpers** | 80%以上 | 100% | ✅ 達成 |
| **Mailers** | 100% | 100% | ✅ 達成 |
| **Views** | 70%以上 | 25% | ⚠️ 要改善 |

**備考**: Phase 4でSystemテスト追加により、Views カバレッジ向上を目指す

### コード品質

| 指標 | 目標 | 現在 | ステータス |
|------|------|------|-----------|
| **RuboCop違反** | 0件 | 0件 | ✅ 達成 |
| **Brakeman警告** | 0件（High/Critical） | 0件 | ✅ 達成 |

---

## リスク管理

### 現在のリスク

| リスク | 発生確率 | 影響度 | 対策 | ステータス |
|--------|---------|--------|------|-----------|
| iPad/Safari表示崩れ | 中 | 中 | Tom Select利用、実機テスト | 🟡 監視中 |
| スケジュール遅延 | 中 | 低 | スコープ調整可能 | 🟡 監視中 |
| レスポンシブ対応の複雑化 | 低 | 低 | Tailwind活用 | 🟢 問題なし |

### 完了したリスク

なし（Phase 4開始直後）

---

## 変更履歴

### 2025-10-13
- **Phase 4開始**
- `feature/p4-01-header-navigation` ブランチ作成
- Phase 4ドキュメント整備完了:
  - `overview.md`: Phase 4の位置づけ、スコープ定義
  - `workflow.md`: ブランチ戦略、PRプロセス、CI/CD設定
  - `progress.md`: 本ファイル作成

---

## 次回更新予定

- **ヘッダーコンポーネント実装完了時**
- **PR作成時**
- **PR マージ時**

---

## 関連ドキュメント

- [Phase 4 Overview](./overview.md) - Phase 4全体概要
- [Phase 4 Workflow](./workflow.md) - ワークフロー・PRプロセス
- [Phase 3 Progress](../phase3/progress.md) - Phase 3進捗（参考）
- [Screen Design](../../08_screen_design.md) - 画面設計仕様

---

**Document Version**: 1.0
**Last Updated**: 2025-10-13
**Next Review**: ヘッダー実装完了時

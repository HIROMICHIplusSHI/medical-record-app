# Phase 5-B: ブランチ戦略

**作成日**: 2025-10-15
**目的**: Phase 5-Bを適切なサイズのPRに分割し、レビューとマージを容易にする

---

## 🎯 分割方針

Phase 5-Bを3つのサブフェーズに分割:

1. **Phase 5-B-1**: データモデル基盤（Invoice/InvoiceItemモデル）
2. **Phase 5-B-2**: 請求書生成機能（サービスクラス + 基本CRUD）
3. **Phase 5-B-3**: PDF生成機能（InvoicePdfGenerator + 統合）

---

## Phase 5-B-1: データモデル基盤

**ブランチ**: `feature/p5b1-invoice-models`
**推定工数**: 2-3日
**PR規模**: 小（200-300行）

### 実装内容

#### 1. マイグレーション
- [ ] `create_invoices` マイグレーション
- [ ] `create_invoice_items` マイグレーション
- [ ] `db:migrate` 実行

#### 2. モデル実装
- [ ] Invoice モデル
  - リレーション定義
  - バリデーション実装
  - enum設定（status）
  - 請求書番号自動生成ロジック
  - 合計金額計算ロジック
  - スコープ定義
  - Ransack設定
- [ ] InvoiceItem モデル
  - リレーション定義
  - バリデーション実装
  - コールバック実装（invoice合計更新）

#### 3. Factory定義
- [ ] Invoice Factory
- [ ] InvoiceItem Factory

#### 4. Model Spec
- [ ] Invoice Spec（15-20件）
  - バリデーションテスト
  - 請求書番号自動生成テスト
  - 合計金額計算テスト
  - スコープテスト
  - Ransack設定テスト
- [ ] InvoiceItem Spec（8-10件）
  - バリデーションテスト
  - コールバックテスト
  - リレーションテスト

### 完了条件
- [ ] マイグレーション成功
- [ ] Model Spec全てパス
- [ ] RuboCop違反なし
- [ ] Brakeman警告なし

### コミット分割例
```bash
git commit -m "feat(model): add invoices migration"
git commit -m "feat(model): add invoice_items migration"
git commit -m "feat(model): add Invoice model with validations"
git commit -m "feat(model): add InvoiceItem model with callbacks"
git commit -m "feat(model): add invoice number auto-generation"
git commit -m "test(invoice): add Invoice model specs"
git commit -m "test(invoice): add InvoiceItem model specs"
```

---

## Phase 5-B-2: 請求書生成機能

**ブランチ**: `feature/p5b2-invoice-generator`
**推定工数**: 3-4日
**PR規模**: 中（400-500行）

### 実装内容

#### 1. サービスクラス
- [ ] InvoiceGenerator実装
  - カルテ自動集計ロジック
  - 請求書明細作成ロジック
  - エラーハンドリング
  - トランザクション処理
- [ ] InvoiceGenerator Spec（10-12件）

#### 2. コントローラー（基本CRUD）
- [ ] InvoicesController実装
  - index アクション（一覧）
  - show アクション（詳細）
  - new/create アクション（作成）
  - edit/update アクション（編集）
  - destroy アクション（削除）
- [ ] ルーティング設定

#### 3. ビュー（基本画面）
- [ ] 請求書一覧ビュー
  - 一覧表示
  - 検索フォーム（Ransack）
  - ページネーション
- [ ] 請求書詳細ビュー
  - 請求書情報表示
  - 明細テーブル
  - アクションボタン
- [ ] 請求書作成フォーム
  - 施設選択
  - 請求期間入力
- [ ] 請求書編集フォーム

#### 4. Request Spec
- [ ] 認証テスト（2件）
- [ ] CRUD操作テスト（12-15件）

#### 5. System Spec（基本フロー）
- [ ] 請求書一覧テスト（3-4件）
- [ ] 請求書作成テスト（4-5件）
- [ ] 請求書詳細テスト（2-3件）
- [ ] 検索機能テスト（2-3件）

### 完了条件
- [ ] 請求書のCRUD操作が動作
- [ ] カルテから請求書を自動生成できる
- [ ] テスト全てパス
- [ ] RuboCop違反なし
- [ ] N+1クエリなし

### コミット分割例
```bash
git commit -m "feat(service): add InvoiceGenerator service"
git commit -m "test(service): add InvoiceGenerator specs"
git commit -m "feat(controller): add InvoicesController basic CRUD"
git commit -m "feat(view): add invoice list and search views"
git commit -m "feat(view): add invoice detail view"
git commit -m "feat(view): add invoice form views"
git commit -m "test(invoice): add request specs for CRUD"
git commit -m "test(invoice): add system specs for basic flow"
```

---

## Phase 5-B-3: PDF生成機能

**ブランチ**: `feature/p5b3-pdf-generation`
**推定工数**: 3-4日
**PR規模**: 中（300-400行）

### 実装内容

#### 1. 日本語フォント設定
- [ ] IPAexゴシックフォントのダウンロード
- [ ] フォントファイルの配置（`app/assets/fonts/`）
- [ ] .gitignore設定確認（フォントをリポジトリに含める）

#### 2. Prawn gem追加
- [ ] Gemfile に `prawn`, `prawn-table` 追加
- [ ] `bundle install`

#### 3. PDF生成サービス
- [ ] InvoicePdfGenerator実装
  - 日本語フォント設定
  - ヘッダー・請求書情報セクション
  - 請求先情報セクション
  - 明細テーブルセクション
  - 合計金額セクション
  - フッター・振込先情報セクション
- [ ] InvoicePdfGenerator Spec（8-10件）

#### 4. コントローラー（PDF機能）
- [ ] generate_pdf アクション追加
- [ ] download_pdf アクション追加
- [ ] ルーティング追加

#### 5. ビュー更新
- [ ] 詳細ビューにPDF生成ボタン追加
- [ ] PDFダウンロードリンク追加

#### 6. Active Storage設定
- [ ] PDF添付設定（Invoiceモデル）
- [ ] ストレージ設定確認

#### 7. Request Spec（PDF機能）
- [ ] PDF生成テスト（3-4件）
- [ ] PDFダウンロードテスト（2-3件）

#### 8. System Spec（PDF機能）
- [ ] PDF生成フローテスト（3-4件）

### 完了条件
- [ ] 日本語PDFを生成できる
- [ ] PDFダウンロードが動作する
- [ ] テスト全てパス
- [ ] RuboCop違反なし
- [ ] PDF生成時間 < 3秒

### コミット分割例
```bash
git commit -m "chore(font): add IPAex Gothic font for PDF"
git commit -m "feat(gem): add prawn and prawn-table"
git commit -m "feat(service): add InvoicePdfGenerator service"
git commit -m "feat(service): implement PDF header and invoice info"
git commit -m "feat(service): implement PDF items table"
git commit -m "feat(service): implement PDF total and footer"
git commit -m "test(pdf): add InvoicePdfGenerator specs"
git commit -m "feat(controller): add PDF generation actions"
git commit -m "feat(view): add PDF generation UI"
git commit -m "test(pdf): add PDF generation request specs"
git commit -m "test(pdf): add PDF generation system specs"
```

---

## 📊 各PRのサイズ比較

| Phase | 推定行数 | 推定工数 | ファイル数 | テスト数 |
|-------|---------|---------|-----------|---------|
| **5-B-1** | 200-300 | 2-3日 | 6-8 | 25-30 |
| **5-B-2** | 400-500 | 3-4日 | 12-15 | 35-40 |
| **5-B-3** | 300-400 | 3-4日 | 8-10 | 25-30 |
| **合計** | 900-1200 | 8-11日 | 26-33 | 85-100 |

---

## 🔄 マージフロー

```
main
 ├─ feature/p5b1-invoice-models
 │   └─ PR #16 → main にマージ
 │
 ├─ feature/p5b2-invoice-generator (p5b1マージ後)
 │   └─ PR #17 → main にマージ
 │
 └─ feature/p5b3-pdf-generation (p5b2マージ後)
     └─ PR #18 → main にマージ
```

### ブランチ作成の順序

```bash
# Phase 5-B-1
git checkout main
git pull origin main
git checkout -b feature/p5b1-invoice-models

# 実装 → テスト → コミット → PR → マージ

# Phase 5-B-2
git checkout main
git pull origin main  # p5b1 の変更を取得
git checkout -b feature/p5b2-invoice-generator

# 実装 → テスト → コミット → PR → マージ

# Phase 5-B-3
git checkout main
git pull origin main  # p5b2 の変更を取得
git checkout -b feature/p5b3-pdf-generation

# 実装 → テスト → コミット → PR → マージ
```

---

## 🎯 各PRの成功基準

### Phase 5-B-1（モデル基盤）
- [ ] マイグレーション成功
- [ ] モデルSpec全てパス（25-30件）
- [ ] RuboCop違反なし
- [ ] Brakeman警告なし
- [ ] カバレッジ 100%（モデル層のみ）

### Phase 5-B-2（請求書生成）
- [ ] サービスSpec全てパス（10-12件）
- [ ] Request Spec全てパス（14-17件）
- [ ] System Spec全てパス（11-15件）
- [ ] RuboCop違反なし
- [ ] N+1クエリなし（Bullet確認）
- [ ] 請求書CRUD操作が正常に動作

### Phase 5-B-3（PDF生成）
- [ ] PDF生成Spec全てパス（8-10件）
- [ ] Request Spec全てパス（5-7件）
- [ ] System Spec全てパス（3-4件）
- [ ] RuboCop違反なし
- [ ] 日本語PDFが正しく生成される
- [ ] PDF生成時間 < 3秒

---

## 📝 ドキュメント更新タイミング

### Phase 5-B-1完了時
- データモデル図の更新（`docs/02_data_model.md`）
- gap_analysis.md の更新

### Phase 5-B-2完了時
- 詳細設計書の更新（`docs/07_detailed_design.md`）
- 画面設計書の更新（`docs/08_screen_design.md`）

### Phase 5-B-3完了時
- Phase 5-B完了報告書の作成（`docs/phases/phase5/completed/phase5b_invoice_generation.md`）
- gap_analysis.md の最終更新

---

## 🔍 コードレビュー方針

### Phase 5-B-1（モデル基盤）
**重点確認項目**:
- マイグレーションの整合性
- バリデーションの妥当性
- 請求書番号生成ロジックの一意性
- テストカバレッジ

**推奨レビュアー**: quality-engineer, root-cause-analyst

### Phase 5-B-2（請求書生成）
**重点確認項目**:
- InvoiceGenerator のビジネスロジック
- トランザクション処理の正確性
- N+1クエリの有無
- エラーハンドリング

**推奨レビュアー**: performance-engineer, quality-engineer

### Phase 5-B-3（PDF生成）
**重点確認項目**:
- PDF出力の正確性
- 日本語フォントの表示確認
- ファイルサイズとパフォーマンス
- セキュリティ（ファイル名サニタイズ等）

**推奨レビュアー**: security-engineer, quality-engineer

---

## 🚀 次のステップ

### 現在地
- [x] Phase 5-B実装計画書作成
- [x] ブランチ戦略策定

### これから
1. **Phase 5-B-1開始**: `git checkout -b feature/p5b1-invoice-models`
2. マイグレーション作成
3. TDDでモデル実装

---

**作成者**: Claude Code
**最終更新**: 2025-10-15

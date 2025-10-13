# Phase 3: 実装進捗記録

**作成日**: 2025-10-13
**最終更新**: 2025-10-13
**バージョン**: 1.2

---

## 目次

1. [進捗サマリー](#1-進捗サマリー)
2. [Phase 3-03: カルテ+コスト項目（完了）](#2-phase-3-03-カルテコスト項目完了)
3. [Phase 3-04: コストシート連携+UI改善（完了）](#3-phase-3-04-コストシート連携ui改善完了)
4. [次のタスク](#4-次のタスク)

---

## 1. 進捗サマリー

### 完了したPR

| PR# | 機能 | ステータス | マージ日 |
|-----|------|----------|---------|
| #4 | コストシート管理 | ✅ マージ済み | 2025-10-13 |
| #5 | カルテ基本機能 | ✅ マージ済み | 2025-10-13 |
| #6 | カルテ+コスト項目+コストシート連携+Tom Select | ✅ マージ済み | 2025-10-13 |

### 実装済み機能

- ✅ コストシート管理（CRUD）
- ✅ カルテ管理（CRUD）
- ✅ コスト項目（nested attributes + 動的追加）
- ✅ コストシート連携（自動入力機能）
- ✅ Tom Select導入（iPad/Safari対応）
- ✅ 患者検索・ページネーション
- ✅ 問診票UI改善

### 未実装機能

- ⏳ 画像アップロード（Active Storage）
- ⏳ タグ機能
- ⏳ 検索強化（Ransack）
- ⏳ E2Eテスト拡充

---

## 2. Phase 3-03: カルテ+コスト項目（完了）

### 実装内容

**PR #3**: カルテ管理 + コスト項目機能

#### 実装機能
- MedicalRecordモデル（カルテ）
  - 患者・施術場所との関連
  - 来院日、施術部位、主訴、診断、施術内容、メモ
  - コスト項目のネスト管理
  - 合計金額の自動計算

- CostItemモデル（コスト項目）
  - 項目名、数量、単価、合計金額
  - ネストされた属性での管理
  - バリデーション

- 動的フォーム（Stimulus.js）
  - コスト項目の追加・削除
  - 金額の自動計算
  - リアルタイム合計表示

#### テスト
- モデルテスト: バリデーション、アソシエーション
- Requestテスト: CRUD操作、ネスト属性
- Systemテスト: E2E動作確認（10ケース）

#### 技術的ポイント
- `accepts_nested_attributes_for`でコスト項目管理
- Stimulusコントローラーで動的フォーム実装
- 合計金額の自動計算ロジック

#### 成果
- ✅ カルテ作成・編集・削除・一覧表示
- ✅ コスト項目の動的追加・削除
- ✅ 金額の自動計算
- ✅ テストカバレッジ維持

---

## 3. Phase 3-04: コストシート連携+UI改善（完了）

### 実装日
2025-10-13

### 実装内容

#### 3.1 コストシート連携機能

**マイグレーション**:
```ruby
# db/migrate/20251013021339_add_cost_sheet_to_cost_items.rb
add_reference :cost_items, :cost_sheet, null: true, foreign_key: true
```

**モデル変更**:
- CostItem に `belongs_to :cost_sheet, optional: true` 追加
- コストシート選択時に項目名と単価を自動入力

**コントローラー変更**:
- `@cost_sheets` の読み込み追加
- `cost_sheet_id` をパラメータに追加

**ビュー変更**:
- コストシート選択ドロップダウン追加
- JavaScript自動入力機能実装

#### 3.2 Tom Select導入（iPad/Safari対応）

**課題**:
ネイティブ`<select>`要素のドロップダウンオプションがiPad/Safariで文字が小さすぎて選択しづらい。iOS Safariではネイティブピッカー UIが使われるため、CSSでスタイルを変更できない。

**解決策**:
Tom Select v2.3.1ライブラリを導入してカスタマイズ可能なドロップダウンに置き換え。

**実装詳細**:

1. **importmap設定**:
```ruby
# config/importmap.rb
pin "tom-select", to: "https://cdn.jsdelivr.net/npm/tom-select@2.3.1/+esm"
```

2. **Stimulusコントローラー作成**:
```javascript
// app/javascript/controllers/tom_select_controller.js
import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

export default class extends Controller {
  connect() {
    const defaultOptions = {
      create: false,
      sortField: { field: "text", direction: "asc" },
      maxOptions: 200,
      controlInput: '<input type="text" autocomplete="off" size="1" class="text-xl">',
      dropdownParent: 'body',
      render: {
        option: (data, escape) => {
          return `<div class="option text-xl py-3 px-4">${escape(data.text)}</div>`;
        },
        item: (data, escape) => {
          return `<div class="item text-xl">${escape(data.text)}</div>`;
        }
      }
    }

    const options = { ...defaultOptions, ...this.optionsValue }
    this.tomSelect = new TomSelect(this.element, options)
  }

  disconnect() {
    if (this.tomSelect) {
      this.tomSelect.destroy()
    }
  }
}
```

3. **CSSカスタマイズ**:
```css
/* app/assets/stylesheets/application.css */
.ts-wrapper .ts-control {
  min-height: 44px;
  padding: 10px 14px;
  font-size: 16px;
  line-height: 1.5;
}

.ts-dropdown .option {
  font-size: 16px;
  padding: 12px 14px;
  min-height: 44px;
  line-height: 1.5;
}

.ts-dropdown .option.active {
  background-color: #3b82f6;
  color: white;
}
```

4. **適用箇所**:
- 患者選択ドロップダウン
- 施術場所選択ドロップダウン
- コストシート選択ドロップダウン

**UIの改善点**:
- 16pxの読みやすい文字サイズ
- 44pxのタップしやすい高さ
- カスタム検索機能
- キーボード操作対応
- アクセシビリティ向上

#### 3.3 金額表示の改善

**課題**:
日本円は1円未満がないため、小数点以下の表示は不要。

**解決策**:

1. **入力フィールド変更**:
```erb
<%= f.number_field :unit_price, step: 1, min: 0, class: "..." %>
```

2. **表示の整数化**:
```erb
<!-- カルテ詳細画面 -->
¥<%= number_with_delimiter(cost_item.unit_price.to_i) %>
¥<%= number_with_delimiter(cost_item.total_price.to_i) %>
¥<%= number_with_delimiter(@medical_record.total_cost.to_i) %>
```

#### 3.4 サンプルデータ追加

**施術場所テンプレート**:
```ruby
# db/seeds.rb
facilities_data = [
  { name: '本院（東京）', address: '東京都渋谷区〇〇1-2-3', phone: '03-1234-5678' },
  { name: '大阪分院', address: '大阪府大阪市北区△△2-3-4', phone: '06-2345-6789' },
  { name: '名古屋分院', address: '愛知県名古屋市中区□□3-4-5', phone: '052-3456-7890' },
  { name: '福岡分院', address: '福岡県福岡市中央区◇◇4-5-6', phone: '092-4567-8901' }
]
```

#### 3.5 テスト追加

**コストシート連携テスト**:
```ruby
# spec/models/cost_item_spec.rb
describe 'CostSheet連携' do
  it 'CostSheetと任意で関連付けられる' do
    cost_item = build(:cost_item, cost_sheet: cost_sheet)
    expect(cost_item.valid?).to be true
    expect(cost_item.cost_sheet).to eq(cost_sheet)
  end

  it 'CostSheetなしでも作成できる' do
    cost_item = build(:cost_item, cost_sheet: nil)
    expect(cost_item.valid?).to be true
    expect(cost_item.cost_sheet).to be_nil
  end
end
```

**Rubocop修正**:
- 19件の違反を自動修正
- 数値リテラルのアンダースコア追加
- トレーリングカンマの追加

### 技術的課題と解決

#### 課題1: Tom Selectのimportmapエラー

**エラー**:
```
TomSelect is not loaded yet
```

**原因**:
CDN URLが通常版（UMD）でES Moduleとして読み込めない。

**解決策**:
ESM版のCDN URLに変更:
```ruby
pin "tom-select", to: "https://cdn.jsdelivr.net/npm/tom-select@2.3.1/+esm"
```

#### 課題2: CSSの!important使用

**ユーザー要望**:
`!important`は基本使わない設計にしてほしい。

**解決策**:
1. Tailwindクラスを直接ビューで変更（`text-lg` → `text-xl`）
2. Tom SelectのCSSは通常のセレクタで記述
3. 特異性の高いセレクタを使用して優先度を確保

### 成果

- ✅ コストシート連携機能完成
- ✅ Tom Select導入でiPad/Safari対応完了
- ✅ ドロップダウンUI大幅改善
- ✅ 金額表示を整数のみに統一
- ✅ 施術場所サンプルデータ作成
- ✅ テスト追加・Rubocop修正完了

### コミット

```bash
git commit -m "feat: コストシート連携とTom Select導入でドロップダウンUI改善

## 実装内容

### コストシート連携
- CostItemにcost_sheet_id外部キーを追加（optional）
- コストシート選択時に項目名と単価を自動入力する機能
- 施術場所のサンプルデータ追加（本院・大阪・名古屋・福岡）

### Tom Select導入（iPad/Safari対応）
- importmapでTom Select v2.3.1をESM版で導入
- Stimulusコントローラーで自動初期化
- カスタムCSS: 16px文字サイズ、44px高さでタップしやすく
- 患者・施設・コストシート選択に適用

### UI改善
- 金額フィールドを整数のみ入力に変更（step: 1）
- 表示も整数のみに統一（.to_i）
- プロンプト文字を簡潔に変更
- ネイティブselectの制約を解決し読みやすいUI実現

### テスト
- コストシート連携のテストを追加
- 既存テストのRubocop違反を修正

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## 4. 未実装機能と先延ばし課題

### 4.1 Phase 3 残りの実装

#### Phase 3中盤（機能実装優先）

| タスク | 優先度 | 推定時間 | 詳細 |
|--------|--------|---------|------|
| 画像アップロード（Active Storage） | 🔴 高 | 4h | カルテに施術写真を添付（最大5枚） |
| タグ機能 | 🟡 中 | 3h | Tag + MedicalRecordTag中間テーブル |
| 検索強化（Ransack） | 🟡 中 | 3h | 複雑な条件での検索機能 |

#### Phase 3後半（機能実装完了後）

| タスク | 優先度 | 推定時間 | 詳細 |
|--------|--------|---------|------|
| System E2Eテスト拡充 | 🔴 高 | 6-8h | 全機能の統合テスト（仕様固定後に実施） |
| UI/UX最終調整 | 🟢 低 | 2h | アクセシビリティ・レスポンシブ対応 |

**E2E延期理由**:
- 現在機能追加中で仕様変更が頻繁
- 仕様固定後に一気に書く方が効率的
- CI実行時間の最適化も同時実施

### 4.2 Important Issues（Phase 4持ち越し）

PR #6のコードレビューで発見された改善項目。現状動作しているが、保守性・品質向上のため将来対応が必要。

#### Issue #3: JavaScript イベントリスナーの重複問題
**問題**: DOM cloneでイベントリスナーが重複する可能性（アンチパターン）

**現在の実装**:
```javascript
// app/javascript/controllers/cost_items_controller.js:1248
addItem(event) {
  const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
  this.containerTarget.insertAdjacentHTML('beforeend', content)
}
```

**推奨改善策**:
- イベント委譲パターンの使用
- Stimulusのtarget機能を活用
- クローンではなく動的生成に変更

**優先度**: 🟡 中
**推定工数**: 2h
**対応時期**: Phase 4

#### Issue #4: JavaScript/Ruby 小数点処理の不一致
**問題**: JavaScriptはFloat、RubyはDecimalで計算

**現状**:
```javascript
// JavaScript側（Float演算）
const subtotal = price * qty
```

```ruby
# Ruby側（Decimal演算）
self.subtotal = unit_price * quantity
```

**推奨改善策**:
- JavaScript側でDecimal.jsライブラリ使用
- または、整数のみの金額計算に統一

**優先度**: 🟢 低（日本円は小数なし、実害なし）
**推定工数**: 1h
**対応時期**: Phase 4

#### Issue #5: System E2Eテストの不足
**問題**: JavaScript動作のE2Eテストがない（現在無効化中）

**テスト不足箇所**:
- コスト項目の動的追加・削除
- 金額計算のリアルタイム更新
- Tom Selectの動作
- コストシート連携の自動入力
- 画像アップロード（未実装）
- タグ機能（未実装）
- 検索機能（未実装）

**推奨改善策**:
- Capybara + Selenium/Cuprite でSystemテスト追加
- JavaScriptドライバーでの動作確認
- エッジケースのテストケース追加
- CI実行時間の最適化

**優先度**: 🔴 高（JavaScriptの品質保証）
**推定工数**: 6-8h
**対応時期**: Phase 3後半（全機能実装後）
**延期理由**: 仕様変更頻度が高く、機能固定後に一気に書く方が効率的

### 4.3 設計書との整合性確認

#### ✅ 整合性OK
- User, Facility, Patient, Questionnaire: Phase 2で実装完了
- CostSheet, CostItem, MedicalRecord: Phase 3で実装完了
- ネスト属性、動的フォーム: Phase 3で実装完了

#### ⏳ 未実装（設計書に記載あり）
- **Tag, MedicalRecordTag**: タグ機能（Phase 3残り）
- **Invoice**: 請求書機能（Phase 4予定）
- **Active Storage設定**: 画像アップロード（Phase 3残り）
- **Ransack gem**: 高度な検索（Phase 3残り）

#### ℹ️ 設計書との差異
- **MedicalRecord属性**: 設計書には`counseling_content`があるが、実装では以下に変更:
  - `visit_date` (来院日)
  - `treatment_location` (施術部位)
  - `chief_complaint` (主訴)
  - `diagnosis` (診断)
  - `treatment_content` (施術内容)
  - `notes` (メモ)
- **理由**: より実用的なカルテ項目に変更

### 4.4 次回セッション推奨

#### Phase 3中盤の実装順序

**優先度1**: 画像アップロード機能（Active Storage）
- **理由**: カルテ機能の重要な要素、ユーザー要望高
- **工数**: 4h
- **ブランチ**: `feature/p3-05-image-upload`

**優先度2**: タグ機能
- **理由**: カルテ分類・検索の基盤
- **工数**: 3h
- **ブランチ**: `feature/p3-06-tags`

**優先度3**: 検索強化（Ransack）
- **理由**: タグ機能と組み合わせて高度な検索を実現
- **工数**: 3h
- **ブランチ**: `feature/p3-08-ransack-search`

#### Phase 3後半（全機能実装後）

**最終仕上げ**: System E2Eテスト拡充
- **理由**: 仕様固定後に一気に書く（CI最適化含む）
- **工数**: 6-8h
- **ブランチ**: `feature/p3-09-e2e-tests`

**準備**:
```bash
# 次回セッション開始時（画像アップロードから）
git checkout main && git pull
git checkout -b feature/p3-05-image-upload
```

---

## 変更履歴

| バージョン | 日付 | 変更内容 |
|-----------|------|---------|
| 1.0 | 2025-10-13 | 初版作成 - Phase 3-03, 3-04完了記録 |
| 1.1 | 2025-10-13 | PR番号修正 (#4-6), PR #6マージ完了記録 |
| 1.2 | 2025-10-13 | 未実装機能・Important Issues・設計書整合性を追加、E2E実装タイミング調整 |

---

**Last Updated**: 2025-10-13

# Phase 6.5: UI/UX改善・InkFolioブランド適用

**作成日**: 2025-10-23
**状態**: 進行中
**目的**: InkFolioブランドデザインの適用とアクセシビリティ・品質向上

---

## 📊 概要

Phase 6.5では、アプリケーション全体にInkFolioブランドカラーを適用し、UI/UXの一貫性とアクセシビリティを向上させます。

### InkFolioカラーパレット

```css
/* Primary Colors */
--color-accent-primary: #8b7355    /* InkFolioブラウン - メインブランドカラー */
--color-ink-dark: #6b5a3f          /* テキスト用の暗いブラウン（WCAG対応） */
--color-accent-secondary: #b5a188   /* セカンダリブラウン */

/* Semantic Colors */
--color-accent-success: #7a9b76    /* 成功・完了 */
--color-accent-warning: #d4a574    /* 警告・注意 */
--color-accent-danger: #c17b7b     /* 危険・削除 */
--color-accent-info: #7b9bc1       /* 情報 */

/* Neutral Palette */
--color-greige-50: #fafaf9         /* 最も明るい */
--color-greige-100: #f5f5f4
--color-greige-200: #e7e5e4
--color-greige-300: #d6d3d1
--color-greige-400: #a8a29e
--color-greige-500: #78716c
--color-greige-600: #57534e
--color-greige-700: #44403c
--color-greige-800: #292524
--color-greige-900: #1c1917        /* 最も暗い */
```

### ブランドコンセプト

- **Professional（プロフェッショナル）**: 医療記録アプリとしての信頼性
- **Warm（温かみ）**: 美容業界に合わせた親しみやすさ
- **Natural（自然）**: アースカラーで落ち着いた雰囲気

---

## 🎯 全体計画

| Phase | 内容 | 工数 | 状態 |
|-------|------|------|------|
| **6.5-1** | ブランドカラー適用（全ページ） | 完了 | ✅ PR #33 |
| **6.5-2** | アクセシビリティ改善 | 3.5-6.5h | 🔄 進行中 |
| **6.5-3** | コンポーネント統一 | 6-10h | ⏳ 予定 |
| **6.5-4** | ホーム画面改修 | 4-6h | ⏳ 予定 |
| **6.5-5** | 最終仕上げ | 2-3h | ⏳ 予定 |

**合計工数**: 16-26時間（2-3日分）

---

## ✅ Phase 6.5-1: ブランドカラー適用（完了）

**PR**: #33
**ブランチ**: `feature/phase6.5-ui-ux-improvement`
**期間**: 2025-10-22 〜 2025-10-23
**状態**: マージ待ち

### 実装内容

#### 1. Tailwind CSSセットアップ

**ファイル**: `app/assets/stylesheets/application.tailwind.css`

```css
@theme {
  /* InkFolioカラーテーマ追加 */
  --color-accent-primary: #8b7355;
  --color-ink-dark: #6b5a3f;
  --color-greige-*: ...;
}
```

#### 2. レイアウトファイル更新

**ファイル**:
- `app/views/layouts/application.html.erb`
- `app/views/shared/_header.html.erb`
- `app/views/shared/_footer.html.erb`

**変更点**:
- アプリ名を「電子カルテ」→「InkFolio」に変更
- ロゴ画像追加（`app/assets/images/logo.svg`）
- ヘッダーナビゲーションのホバー色をInkFolioブラウンに統一

#### 3. 全ページへのデザイン適用

**色変換パターン（40+パターン）**:
```bash
# Primaryカラー
bg-blue-500 → bg-accent-primary
text-blue-600 → text-accent-primary
hover:bg-blue-700 → hover:bg-accent-primary/90

# Neutralカラー
bg-gray-50 → bg-greige-50
text-gray-900 → text-greige-900

# Semanticカラー
bg-green-500 → bg-accent-success
bg-yellow-500 → bg-accent-warning
bg-red-500 → bg-accent-danger
```

**更新ファイル数**: 80+ files
**変更行数**: 約1,500行

**更新ページカテゴリ（15種類）**:
1. ダッシュボード（売上管理）
2. カルテ管理
3. 患者管理
4. 施術場所管理
5. コストシート管理
6. 同意書テンプレート管理
7. 同意書作成・署名
8. 請求書管理
9. お問い合わせ
10. 問診票
11. マイページ
12. ホーム
13. タグ管理
14. 管理画面（ダッシュボード、ユーザー管理、お知らせ管理）
15. Devise認証ページ（ログイン、登録、パスワードリセット）

#### 4. インタラクション改善

**transition-colors追加**: 115箇所

```erb
<!-- Before -->
class="bg-accent-primary hover:bg-accent-primary/90"

<!-- After -->
class="bg-accent-primary hover:bg-accent-primary/90 transition-colors"
```

**ホバーステート**: 182箇所
**フォーカスステート**: 164箇所

#### 5. SVGアイコン廃止

**対象**: `app/views/admin/dashboard/index.html.erb`

**変更内容**:
- 総ユーザー数、総カルテ数、公開中のお知らせのSVGアイコンを削除
- シンプルな左ボーダー（`border-l-4`）デザインに変更

**理由**: SVGアイコンが一部ブラウザで表示崩れ → よりシンプルで保守性の高いデザインに

### コミット履歴（20コミット）

```
1. feat(ui): Tailwind CSSカスタムテーマ設定（InkFolioカラー）
2. feat(ui): レイアウトファイル更新（ヘッダー・フッター・ロゴ）
3. feat(ui): ナビゲーションホバー色をInkFolioブラウンに統一
4. feat(ui): アプリ名を「InkFolio」に変更
5. feat(ui): ダッシュボードページのInkFolioデザイン適用
6. feat(ui): カルテページのInkFolioデザイン適用
7. feat(ui): 患者ページのInkFolioデザイン適用
8. feat(ui): 施術場所ページのInkFolioデザイン適用
9. feat(ui): コストシートページのInkFolioデザイン適用
10. feat(ui): 同意書関連ページのInkFolioデザイン適用
11. feat(ui): 請求書ページのInkFolioデザイン適用
12. feat(ui): お問い合わせページのInkFolioデザイン適用
13. feat(ui): 残りページのInkFolioデザイン適用（問診票・マイページ・ホーム・タグ）
14. feat(ui): 管理画面・Devise認証画面のInkFolioデザイン適用
15. fix(ui): 管理者ダッシュボードのSVGアイコンとカラー修正
16. refactor(ui): 管理者ダッシュボードのSVGアイコンを廃止
17. style: RuboCop Layout/LineLength違反を修正
```

### 品質チェック

✅ **RuboCop**: 0違反
✅ **テスト**: 700+ examples, 0 failures
✅ **コミット形式**: Conventional Commits準拠

### frontend-architect レビュー結果

**総合スコア**: 78/100

#### ✅ 評価された点

- 一貫したスペーシングシステム ⭐
- 画像モーダル実装（スワイプ対応） ⭐⭐
- セマンティックカラー使用 ⭐
- レスポンシブグリッドパターン ⭐
- transition-colors適用（115箇所） ⭐

#### 🔴 Critical Issues（Phase 6.5-2で対応）

1. **WCAGコントラスト違反**
   - InkFolioブラウン(#8b7355)が通常テキストで基準未達
   - 現状: 3.8:1 < 4.5:1（必要）

2. **非InkFolioカラーの残存**（6ファイル）
   - patients/show.html.erb
   - patients/_form.html.erb
   - patients/index.html.erb
   - shared/_header.html.erb
   - home/index.html.erb
   - invoices/index.html.erb

3. **ARIA属性不足**
   - ナビゲーションに`aria-current="page"`がない
   - フォームエラーに`aria-describedby`がない

---

## 🔄 Phase 6.5-2: アクセシビリティ改善（進行中）

**ブランチ**: `feature/phase6.5-2-accessibility-quality`
**期間**: 2025-10-23 〜
**状態**: 実装中

### 目的

frontend-architectレビューで指摘された**Critical Issues**を修正し、アクセシビリティスコアを向上させる。

**目標**: スコア 78/100 → 90/100

### 実装内容

#### 1. 非InkFolioカラー修正（6ファイル）

**工数**: 1-2時間

##### 対象ファイルと修正内容

**app/views/patients/show.html.erb**
```erb
<!-- Before -->
<%= link_to 'カルテ追加', new_medical_record_path(patient_id: @patient.id),
    class: 'bg-blue-500 hover:bg-blue-700 text-white' %>

<!-- After -->
<%= link_to 'カルテ追加', new_medical_record_path(patient_id: @patient.id),
    class: 'bg-accent-primary hover:bg-accent-primary/90 text-white transition-colors' %>
```

**修正パターン**:
- `bg-blue-500` → `bg-accent-primary`
- `bg-green-500` → `bg-accent-success`
- `bg-yellow-500` → `bg-accent-warning`
- `bg-red-500` → `bg-accent-danger`
- `text-gray-*` → `text-greige-*`
- `bg-gray-*` → `bg-greige-*`

**app/views/patients/_form.html.erb**
```erb
<!-- Before -->
<div class="bg-blue-50 border-blue-200 text-blue-800 p-4">

<!-- After -->
<div class="bg-accent-primary/10 border-accent-primary text-accent-primary p-4">
```

**app/views/patients/index.html.erb**
```erb
<!-- Before -->
class="hover:bg-gray-700"

<!-- After -->
class="hover:bg-greige-700 transition-colors"
```

**app/views/shared/_header.html.erb**
```erb
<!-- Before -->
class="text-gray-700 hover:bg-gray-100"

<!-- After -->
class="text-greige-700 hover:bg-greige-100 transition-colors"
```

**app/views/home/index.html.erb**
```erb
<!-- Before -->
<div class="bg-indigo-500">
<div class="bg-purple-500">
<div class="bg-yellow-500">

<!-- After -->
<div class="bg-accent-primary">
<div class="bg-accent-secondary">
<div class="bg-accent-warning">
```

**app/views/invoices/index.html.erb**
```erb
<!-- Before -->
<span class="bg-blue-100 text-blue-800">

<!-- After -->
<span class="bg-accent-primary/10 text-accent-primary">
```

#### 2. WCAGコントラスト対応

**工数**: 2-4時間

**問題**:
- `text-accent-primary`(#8b7355)のコントラスト比: 3.8:1（WCAG AA不合格）
- 通常テキスト(14px)には4.5:1が必要

**解決策**:
- テキスト用に`text-ink-dark`(#6b5a3f)を使用
- コントラスト比: 5.2:1（WCAG AA合格）

**修正対象**:
- リンクテキスト
- ラベルテキスト
- 小サイズのテキスト（14px以下）
- ボタン内テキスト（背景が白の場合）

**Before（コントラスト不足）**:
```erb
<%= link_to '詳細', record, class: 'text-accent-primary hover:text-accent-primary/80' %>
<label class="text-accent-primary">施設名</label>
<p class="text-accent-primary">金額: ¥10,000</p>
```

**After（WCAG準拠）**:
```erb
<%= link_to '詳細', record, class: 'text-ink-dark hover:text-accent-primary transition-colors' %>
<label class="text-ink-dark font-medium">施設名</label>
<p class="text-ink-dark">金額: ¥10,000</p>
```

**例外（そのまま使用可能）**:
```erb
<!-- 大きいテキスト（18px+）はOK -->
<h1 class="text-3xl font-bold text-accent-primary">InkFolio</h1>

<!-- 背景色がある場合はOK -->
<button class="bg-accent-primary text-white">保存</button>
```

**影響範囲**: 50+ファイル

**バッチ処理**:
```bash
# リンクテキスト
grep -rl 'text-accent-primary' app/views --include="*.html.erb" | \
  xargs perl -i -pe 's/text-accent-primary(?=.*<a)/text-ink-dark/g'

# ラベル
grep -rl 'text-accent-primary.*label' app/views --include="*.html.erb" | \
  xargs perl -i -pe 's/text-accent-primary/text-ink-dark/g'
```

#### 3. ARIA属性追加

**工数**: 30分

##### 3-1. ナビゲーションにaria-current追加

**ファイル**: `app/helpers/navigation_helper.rb`

**Before**:
```ruby
def link_to_nav_item(text, path, disabled: false)
  # ...
  link_to text, path, class: css_class
end
```

**After**:
```ruby
def link_to_nav_item(text, path, disabled: false)
  css_class = # ...

  if disabled
    content_tag(:span, text, class: css_class)
  else
    link_to text, path,
            class: css_class,
            'aria-current': (current_page?(path) ? 'page' : nil)
  end
end
```

**効果**: スクリーンリーダーが現在のページを正しく読み上げる

##### 3-2. フォームエラーにaria-describedby追加

**ファイル**: `app/views/patients/_form.html.erb`等のフォーム

**Before**:
```erb
<%= f.text_field :name, class: 'form-input' %>
<% if @patient.errors[:name].any? %>
  <p class="text-accent-danger text-sm mt-1">
    <%= @patient.errors[:name].first %>
  </p>
<% end %>
```

**After**:
```erb
<%= f.text_field :name,
    class: 'form-input',
    'aria-describedby': (@patient.errors[:name].any? ? 'name-error' : nil),
    'aria-invalid': @patient.errors[:name].any? %>
<% if @patient.errors[:name].any? %>
  <p id="name-error" class="text-accent-danger text-sm mt-1" role="alert">
    <%= @patient.errors[:name].first %>
  </p>
<% end %>
```

**効果**: スクリーンリーダーがエラーメッセージとフィールドを関連付ける

#### 4. フォーカスステート統一

**工数**: 1-2時間

**現状の問題**:
- フォーカスリングの幅が不統一（`focus:ring-2`の有無がバラバラ）
- `focus:ring-offset-2`の適用がまばら

**統一パターン**:
```erb
<!-- 標準フォーカススタイル -->
class="focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-accent-primary"
```

**適用対象**:
- すべてのボタン
- すべてのリンク
- すべてのフォーム入力
- すべてのインタラクティブ要素

**バッチ処理**:
```bash
# focus:ring のみ → 完全なフォーカススタイルに
for file in app/views/**/*.html.erb; do
  perl -i -pe 's/focus:ring-accent-primary/focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-accent-primary/g' "$file"
done
```

### 完了条件

- [ ] 6ファイルの非InkFolioカラー修正完了
- [ ] text-accent-primary → text-ink-darkの変換完了（50+ファイル）
- [ ] navigation_helper.rbにaria-current追加
- [ ] 主要フォームにaria-describedby追加（5-10ファイル）
- [ ] フォーカスステート統一（全ファイル）
- [ ] RuboCop: 0違反
- [ ] テスト: 全パス
- [ ] frontend-architectレビュー: スコア90+

---

## ⏳ Phase 6.5-3: コンポーネント統一（予定）

**工数**: 6-10時間（TomSelect工数次第）
**状態**: 未着手

### 目的

コードの保守性向上とUI一貫性確保

### 実装内容

#### 1. ボタンヘルパー化

**問題**: 同じボタンパターンが40+箇所に重複

**現状**:
```erb
<!-- Primary Button（40+箇所） -->
<%= link_to '新規作成', new_path,
    class: 'bg-accent-primary hover:bg-accent-primary/90 text-white font-bold py-2 px-4 rounded transition-colors' %>

<!-- Secondary Button（20+箇所） -->
<%= link_to '編集', edit_path,
    class: 'bg-accent-secondary hover:bg-accent-secondary/90 text-white font-bold py-2 px-4 rounded transition-colors' %>

<!-- Danger Button（15+箇所） -->
<%= button_to '削除', path, method: :delete,
    class: 'bg-accent-danger hover:bg-accent-danger/90 text-white font-bold py-2 px-4 rounded transition-colors' %>
```

**改善後**:
```erb
<!-- ヘルパー化 -->
<%= button_primary '新規作成', new_path %>
<%= button_secondary '編集', edit_path %>
<%= button_danger '削除', path, method: :delete %>
```

**実装ファイル**: `app/helpers/button_helper.rb`

```ruby
module ButtonHelper
  # Primaryボタン
  def button_primary(text, path = nil, **options)
    default_class = 'bg-accent-primary hover:bg-accent-primary/90 text-white font-bold py-2 px-4 rounded transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-accent-primary'

    options[:class] = merge_classes(default_class, options[:class])

    if path
      link_to text, path, **options
    else
      button_tag text, **options
    end
  end

  # Secondaryボタン
  def button_secondary(text, path = nil, **options)
    default_class = 'bg-accent-secondary hover:bg-accent-secondary/90 text-white font-bold py-2 px-4 rounded transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-accent-secondary'

    options[:class] = merge_classes(default_class, options[:class])

    if path
      link_to text, path, **options
    else
      button_tag text, **options
    end
  end

  # Dangerボタン
  def button_danger(text, path = nil, **options)
    default_class = 'bg-accent-danger hover:bg-accent-danger/90 text-white font-bold py-2 px-4 rounded transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-accent-danger'

    options[:class] = merge_classes(default_class, options[:class])

    if path
      if options[:method] == :delete
        button_to text, path, **options
      else
        link_to text, path, **options
      end
    else
      button_tag text, **options
    end
  end

  # Outlineボタン（Secondary的な用途）
  def button_outline(text, path = nil, **options)
    default_class = 'border-2 border-accent-primary text-accent-primary hover:bg-accent-primary hover:text-white font-bold py-2 px-4 rounded transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-accent-primary'

    options[:class] = merge_classes(default_class, options[:class])

    if path
      link_to text, path, **options
    else
      button_tag text, **options
    end
  end

  private

  def merge_classes(default_class, custom_class)
    return default_class if custom_class.blank?
    "#{default_class} #{custom_class}"
  end
end
```

**テスト**: `spec/helpers/button_helper_spec.rb`

```ruby
require 'rails_helper'

RSpec.describe ButtonHelper, type: :helper do
  describe '#button_primary' do
    it 'リンクとして出力' do
      result = helper.button_primary('テスト', '/path')
      expect(result).to include('bg-accent-primary')
      expect(result).to include('href="/path"')
      expect(result).to include('テスト')
    end

    it 'ボタンとして出力' do
      result = helper.button_primary('テスト')
      expect(result).to include('bg-accent-primary')
      expect(result).to include('<button')
      expect(result).to include('テスト')
    end
  end

  describe '#button_danger' do
    it 'DELETE methodでbutton_toを使用' do
      result = helper.button_danger('削除', '/path', method: :delete)
      expect(result).to include('bg-accent-danger')
      expect(result).to include('data-method="delete"')
    end
  end
end
```

**移行手順**:
1. `app/helpers/button_helper.rb`作成
2. テスト作成・実行
3. 1ページずつ置き換え（patients/index.html.erbから）
4. 動作確認
5. 全ページ展開

**影響範囲**: 40+ファイル

#### 2. TomSelect統一

**問題**: selectタグの実装が混在
- TomSelect使用箇所
- 通常のselectタグ使用箇所

**現状調査**（Phase 6.5-2後に実施）:
```bash
# TomSelect使用箇所を検索
grep -r 'data-controller="tom-select"' app/views --include="*.html.erb"

# 通常のselectを検索
grep -r 'f.select\|select_tag' app/views --include="*.html.erb"
```

**TomSelect実装パターン**:
```erb
<!-- 現在のTomSelect実装 -->
<%= f.select :facility_id,
    options_for_select(@facilities.map { |f| [f.name, f.id] }),
    { include_blank: '施設を選択' },
    { class: 'form-select', data: { controller: 'tom-select' } } %>
```

**統一後の標準パターン**:
```erb
<!-- すべてのselectをTomSelectに -->
<%= f.select :facility_id,
    options_for_select(@facilities.map { |f| [f.name, f.id] }),
    { include_blank: '選択してください' },
    { class: 'form-select',
      data: {
        controller: 'tom-select',
        tom_select_placeholder_value: '選択してください'
      }
    } %>
```

**Stimulus Controller拡張**:

`app/javascript/controllers/tom_select_controller.js`:
```javascript
import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

export default class extends Controller {
  static values = {
    placeholder: String,
    maxItems: Number,
    searchField: Array,
    create: Boolean
  }

  connect() {
    this.tomSelect = new TomSelect(this.element, {
      placeholder: this.placeholderValue || '選択してください',
      maxItems: this.maxItemsValue || 1,
      searchField: this.searchFieldValue || ['text'],
      create: this.createValue || false,
      plugins: {
        remove_button: {
          title: '削除'
        }
      },
      render: {
        no_results: () => {
          return '<div class="no-results">該当する項目がありません</div>'
        }
      }
    })
  }

  disconnect() {
    if (this.tomSelect) {
      this.tomSelect.destroy()
    }
  }
}
```

**優先順位**:
1. **高**: カルテ作成・編集（施設選択、患者選択）
2. **中**: 請求書作成（施設選択）、問診票（各種選択）
3. **低**: フィルター用select

**工数見積もり**:
- 調査: 1時間
- 実装: 2-4時間（件数次第）
- テスト: 1-2時間
- **合計**: 4-7時間

※工数が大きい場合は優先度の高いものだけ実施し、残りは別Phaseに

### 完了条件

- [ ] ButtonHelper実装・テスト完了
- [ ] 全ページでボタンヘルパー使用
- [ ] TomSelect調査完了
- [ ] 高優先度selectのTomSelect化完了
- [ ] RuboCop: 0違反
- [ ] テスト: 全パス

---

## ⏳ Phase 6.5-4: ホーム画面改修（予定）

**工数**: 4-6時間
**状態**: 未着手

### 目的

ログインフローの最適化とユーザーホーム画面のUX改善

### 背景・課題

#### 現状の問題

1. **アプリホームURL直接アクセス時のエラー**
   - 現在の`root_path`は`home#index`（ログイン必須）
   - 未ログイン状態で直接アクセスするとフラッシュメッセージ表示
   - その後ログインページにリダイレクト（UXが悪い）

2. **ヘッダーロゴの遷移先が不適切**
   - ログイン前: ロゴクリック → ホーム（エラー） → ログインページ
   - ログイン後: ロゴクリック → ホーム（現状）

3. **ユーザーホーム画面の内容が不十分**
   - 各ページへのリンクのみ（ヘッダーナビと重複）
   - 管理者からのお知らせが見づらい
   - 本日のタスクが一目でわからない

### 実装内容

#### 1. ルーティング変更

**Before** (`config/routes.rb`):
```ruby
Rails.application.routes.draw do
  root 'home#index'  # ログイン必須

  # ...
end
```

**After** (`config/routes.rb`):
```ruby
Rails.application.routes.draw do
  # ルートはログインページ兼アプリ紹介ページ
  root 'welcome#index'

  # ユーザー用ダッシュボード（ログイン後のホーム）
  get 'dashboard', to: 'user_dashboard#index', as: :user_dashboard

  # 既存のホームページは削除
  # get 'home', to: 'home#index'  # 削除

  # ...
end
```

#### 2. Welcomeコントローラー作成（ログインページ兼アプリ紹介）

**ファイル**: `app/controllers/welcome_controller.rb`

```ruby
class WelcomeController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    # ログイン済みの場合は適切なホームへリダイレクト
    if user_signed_in?
      redirect_to after_sign_in_path_for(current_user)
    end
  end
end
```

**ビュー**: `app/views/welcome/index.html.erb`

```erb
<div class="min-h-screen bg-gradient-to-b from-greige-50 to-white">
  <!-- ヒーローセクション -->
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-20 pb-16">
    <div class="text-center">
      <%= image_tag 'logo.svg', alt: 'InkFolio', class: 'h-20 mx-auto mb-8' %>

      <h1 class="text-5xl font-bold text-greige-900 mb-6">
        InkFolio
      </h1>

      <p class="text-xl text-greige-600 mb-12 max-w-2xl mx-auto">
        フリーランス美容施術者のための電子カルテ・経営管理システム
      </p>

      <%= button_primary 'ログイン', new_user_session_path, class: 'text-lg px-8 py-3' %>
    </div>
  </div>

  <!-- 機能紹介 -->
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
    <h2 class="text-3xl font-bold text-center text-greige-900 mb-12">主な機能</h2>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
      <!-- カルテ管理 -->
      <div class="bg-white rounded-lg shadow-sm border border-greige-200 p-6">
        <div class="w-12 h-12 bg-accent-primary/10 rounded-lg flex items-center justify-center mb-4">
          <svg class="w-6 h-6 text-accent-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
          </svg>
        </div>
        <h3 class="text-xl font-bold text-greige-900 mb-2">電子カルテ管理</h3>
        <p class="text-greige-600">
          施術記録を写真付きで管理。同意書の電子署名にも対応。
        </p>
      </div>

      <!-- 売上管理 -->
      <div class="bg-white rounded-lg shadow-sm border border-greige-200 p-6">
        <div class="w-12 h-12 bg-accent-success/10 rounded-lg flex items-center justify-center mb-4">
          <svg class="w-6 h-6 text-accent-success" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
        <h3 class="text-xl font-bold text-greige-900 mb-2">売上管理</h3>
        <p class="text-greige-600">
          月次・年次売上をリアルタイム集計。請求書も自動生成。
        </p>
      </div>

      <!-- 患者管理 -->
      <div class="bg-white rounded-lg shadow-sm border border-greige-200 p-6">
        <div class="w-12 h-12 bg-accent-info/10 rounded-lg flex items-center justify-center mb-4">
          <svg class="w-6 h-6 text-accent-info" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
          </svg>
        </div>
        <h3 class="text-xl font-bold text-greige-900 mb-2">患者管理</h3>
        <p class="text-greige-600">
          個人情報を暗号化して安全に管理。問診票機能も搭載。
        </p>
      </div>
    </div>
  </div>

  <!-- セキュリティ・プライバシー -->
  <div class="bg-greige-50 py-16">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="text-center">
        <h2 class="text-2xl font-bold text-greige-900 mb-4">
          安心のセキュリティ
        </h2>
        <p class="text-greige-600 max-w-2xl mx-auto">
          個人情報は暗号化して保存。医療情報を安全に管理します。
        </p>
      </div>
    </div>
  </div>
</div>
```

#### 3. UserDashboardコントローラー作成

**ファイル**: `app/controllers/user_dashboard_controller.rb`

```ruby
class UserDashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_not_admin

  def index
    # 管理者からのお知らせ（最新5件）
    @announcements = Announcement.published.order(published_at: :desc).limit(5)

    # 本日の施術予定
    @today_medical_records = current_user.medical_records
                                         .where(treatment_date: Date.today)
                                         .includes(:patient, :facility)
                                         .order(created_at: :desc)

    # 今週の施術件数
    @week_count = current_user.medical_records
                              .where(treatment_date: Date.today.beginning_of_week..Date.today.end_of_week)
                              .count

    # 今月の売上
    @month_revenue = current_user.medical_records
                                 .where(treatment_date: Date.today.beginning_of_month..Date.today.end_of_month)
                                 .sum(:total_amount)
  end

  private

  def ensure_not_admin
    redirect_to admin_root_path if current_user.admin?
  end
end
```

**ビュー**: `app/views/user_dashboard/index.html.erb`

```erb
<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
  <!-- ヘッダー -->
  <div class="mb-8">
    <h1 class="text-3xl font-bold text-greige-900">ホーム</h1>
    <p class="mt-2 text-sm text-greige-600">本日の予定と最新情報</p>
  </div>

  <!-- 今週の統計 -->
  <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
    <!-- 今週の施術件数 -->
    <div class="bg-white rounded-lg shadow-sm border border-greige-200 p-6">
      <p class="text-sm font-medium text-greige-600">今週の施術件数</p>
      <p class="mt-2 text-4xl font-bold text-accent-primary"><%= @week_count %></p>
    </div>

    <!-- 今月の売上 -->
    <div class="bg-white rounded-lg shadow-sm border border-greige-200 p-6">
      <p class="text-sm font-medium text-greige-600">今月の売上</p>
      <p class="mt-2 text-4xl font-bold text-accent-success">
        <%= number_to_currency(@month_revenue, unit: '¥', precision: 0) %>
      </p>
    </div>
  </div>

  <!-- メインコンテンツ -->
  <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
    <!-- 本日の施術予定 -->
    <div class="bg-white rounded-lg shadow-sm border border-greige-200 p-6">
      <h2 class="text-xl font-bold text-greige-900 mb-4 flex items-center">
        <svg class="w-5 h-5 mr-2 text-accent-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
        </svg>
        本日の施術予定
      </h2>

      <% if @today_medical_records.any? %>
        <div class="space-y-3">
          <% @today_medical_records.each do |record| %>
            <%= link_to medical_record_path(record), class: "block p-4 rounded-lg border border-greige-200 hover:border-accent-primary hover:bg-greige-50 transition-colors" do %>
              <div class="flex items-center justify-between">
                <div>
                  <p class="font-medium text-greige-900"><%= record.patient.name %></p>
                  <p class="text-sm text-greige-600">
                    <%= record.facility.name %> • <%= record.treatment_type %>
                  </p>
                </div>
                <svg class="w-5 h-5 text-greige-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                </svg>
              </div>
            <% end %>
          <% end %>
        </div>
      <% else %>
        <div class="text-center py-8">
          <svg class="w-16 h-16 mx-auto text-greige-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
          </svg>
          <p class="text-greige-500">本日の予定はありません</p>
          <%= button_primary '新しいカルテを作成', new_medical_record_path, class: 'mt-4' %>
        </div>
      <% end %>
    </div>

    <!-- 管理者からのお知らせ -->
    <div class="bg-white rounded-lg shadow-sm border border-greige-200 p-6">
      <h2 class="text-xl font-bold text-greige-900 mb-4 flex items-center">
        <svg class="w-5 h-5 mr-2 text-accent-warning" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
        </svg>
        お知らせ
      </h2>

      <% if @announcements.any? %>
        <div class="space-y-3">
          <% @announcements.each do |announcement| %>
            <div class="p-4 rounded-lg border-l-4 <%= announcement.severity == 'critical' ? 'border-accent-danger bg-accent-danger/5' : announcement.severity == 'warning' ? 'border-accent-warning bg-accent-warning/5' : 'border-accent-primary bg-accent-primary/5' %>">
              <div class="flex items-start justify-between">
                <div class="flex-1">
                  <p class="font-medium text-greige-900"><%= announcement.title %></p>
                  <p class="text-sm text-greige-600 mt-1">
                    <%= truncate(announcement.content, length: 100) %>
                  </p>
                  <p class="text-xs text-greige-500 mt-2">
                    <%= announcement.published_at.strftime('%Y/%m/%d %H:%M') %>
                  </p>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      <% else %>
        <div class="text-center py-8">
          <svg class="w-16 h-16 mx-auto text-greige-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
          </svg>
          <p class="text-greige-500">お知らせはありません</p>
        </div>
      <% end %>
    </div>
  </div>
</div>
```

#### 4. ApplicationController修正

**ファイル**: `app/controllers/application_controller.rb`

```ruby
class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  def after_sign_in_path_for(resource)
    if resource.admin?
      admin_root_path
    else
      user_dashboard_path  # 変更: home_path → user_dashboard_path
    end
  end
end
```

#### 5. ヘッダーのロゴリンク修正

**ファイル**: `app/views/shared/_header.html.erb`

**Before**:
```erb
<%= link_to root_path, class: "flex items-center" do %>
  <%= image_tag 'logo.svg', alt: 'InkFolio', class: 'h-8' %>
<% end %>
```

**After**:
```erb
<%= link_to (user_signed_in? ? after_sign_in_path_for(current_user) : root_path), class: "flex items-center" do %>
  <%= image_tag 'logo.svg', alt: 'InkFolio', class: 'h-8' %>
<% end %>
```

**または専用ヘルパー**:

`app/helpers/navigation_helper.rb`:
```ruby
def home_path_for_user
  return root_path unless user_signed_in?

  if current_user.admin?
    admin_root_path
  else
    user_dashboard_path
  end
end
```

```erb
<%= link_to home_path_for_user, class: "flex items-center" do %>
  <%= image_tag 'logo.svg', alt: 'InkFolio', class: 'h-8' %>
<% end %>
```

### 完了条件

- [ ] WelcomeController作成
- [ ] welcome/index.html.erb作成（アプリ紹介）
- [ ] UserDashboardController作成
- [ ] user_dashboard/index.html.erb作成（お知らせ+施術予定）
- [ ] ルーティング変更
- [ ] ApplicationController#after_sign_in_path_for修正
- [ ] ヘッダーロゴリンク修正
- [ ] 既存のhome#indexを削除
- [ ] RuboCop: 0違反
- [ ] SystemSpec追加（ログインフロー）
- [ ] テスト: 全パス

---

## ⏳ Phase 6.5-5: 最終仕上げ（予定）

**工数**: 2-3時間
**状態**: 未着手

### 目的

アクセシビリティの完成度向上と残タスク対応

### 実装内容

#### 1. スキップリンク追加

**ファイル**: `app/views/layouts/application.html.erb`

**Before**:
```erb
<body class="bg-greige-50 text-greige-900">
  <%= render 'shared/header' %>

  <main>
    <!-- ... -->
  </main>
</body>
```

**After**:
```erb
<body class="bg-greige-50 text-greige-900">
  <!-- スキップリンク（キーボードユーザー向け） -->
  <a href="#main-content" class="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 focus:z-50 bg-accent-primary text-white px-4 py-2 rounded focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-accent-primary">
    メインコンテンツへスキップ
  </a>

  <%= render 'shared/header' %>

  <main id="main-content" tabindex="-1">
    <!-- ... -->
  </main>
</body>
```

**Tailwind CSS設定**:
```css
/* app/assets/stylesheets/application.tailwind.css */
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border-width: 0;
}

.focus\:not-sr-only:focus {
  position: static;
  width: auto;
  height: auto;
  padding: revert;
  margin: revert;
  overflow: visible;
  clip: auto;
  white-space: normal;
}
```

#### 2. frontend-architectレビュー残タスク

**Medium Priority対応**:

- [ ] カード抽出（繰り返しパターン30+箇所）
- [ ] テーブルヘッダー抽出（繰り返しパターン10+箇所）
- [ ] モバイルテーブル最適化（horizontal scroll → card view）

**検討項目**:
- 空ステートイラスト追加
- ブランドテクスチャ・パターン追加

#### 3. 最終動作確認

- [ ] レスポンシブデザイン確認（Chrome DevTools）
- [ ] ブラウザ互換性確認（Chrome, Safari, Firefox）
- [ ] キーボードナビゲーション確認
- [ ] スクリーンリーダー確認（VoiceOver/NVDA）
- [ ] パフォーマンス確認（Lighthouse）

#### 4. ドキュメント更新

- [ ] CLAUDE.md更新（Phase 6.5完了）
- [ ] gap_analysis.md更新
- [ ] README更新（スクリーンショット追加）

### 完了条件

- [ ] スキップリンク実装
- [ ] レスポンシブテスト完了
- [ ] アクセシビリティテスト完了
- [ ] frontend-architectレビュー: スコア95+
- [ ] ドキュメント更新完了

---

## 📈 Phase 6.5全体の成功指標

### 定量指標

| 指標 | 開始時 | 目標 | 最終 |
|------|--------|------|------|
| **frontend-architectスコア** | - | 95+ | - |
| **WCAG準拠率** | 60% | 95%+ | - |
| **コード重複率** | 高 | 中〜低 | - |
| **Lighthouse Accessibility** | - | 90+ | - |

### 定性指標

- [ ] InkFolioブランドイメージの統一
- [ ] 一貫したインタラクションパターン
- [ ] 直感的なログインフロー
- [ ] ユーザーホーム画面の有用性

---

## 📝 関連ドキュメント

- [Phase 6 Overview](./overview.md)
- [Gap Analysis](../../gap_analysis.md)
- [CLAUDE.md](../../CLAUDE.md)

---

**最終更新**: 2025-10-23
**次回更新**: Phase 6.5-2完了時

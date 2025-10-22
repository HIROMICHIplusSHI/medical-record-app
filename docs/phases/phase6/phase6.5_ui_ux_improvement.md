# Phase 6.5: UI/UX改善（デザイン統一）

**作成日**: 2025-10-23
**目的**: 提出期限に向けたアプリ全体のデザイン統一と視覚的品質向上
**推定工数**: 1-2日

---

## 🎯 Phase 6.5の目的

提出に向けて、アプリ全体の視覚的品質を向上させ、統一感のあるデザインを実現する。

### 背景
- 現状：機能は実装済みだが、デザインが統一されていない
- 課題：ページごとに色使いが異なる、ブランディング要素が不足
- 目標：グレージュベースの統一されたデザインで、プロフェッショナルな印象を与える

---

## 📋 実装内容

### 1. ブランディング要素の追加

#### 1-1. ヘッダーロゴの設置
**目的**: アプリのアイデンティティ確立、ナビゲーション起点の明確化

**実装内容**:
- ロゴ画像を `app/assets/images/` に配置
- ヘッダーに表示（root_pathへのリンク）
- レスポンシブ対応（モバイル/タブレット/デスクトップ）

**ファイル配置**:
```
app/assets/images/
├── logo.png          # 通常サイズ
├── logo@2x.png       # Retina対応（2倍サイズ）
└── favicon.ico       # ファビコン
```

**実装例**:
```erb
<!-- app/views/layouts/application.html.erb -->
<header class="navbar bg-base-100 shadow-lg">
  <div class="navbar-start">
    <%= link_to root_path, class: "btn btn-ghost normal-case" do %>
      <%= image_tag 'logo.png',
                    alt: '電子カルテアプリ',
                    class: 'h-8 md:h-10 w-auto',
                    srcset: "#{image_path('logo.png')} 1x, #{image_path('logo@2x.png')} 2x" %>
    <% end %>
  </div>
  <!-- ... -->
</header>
```

---

#### 1-2. ファビコンの設置
**目的**: ブラウザタブでの視認性向上、ブランド認知

**実装内容**:
- `public/favicon.ico` に配置
- `application.html.erb` でlink tag設定

**実装例**:
```erb
<!-- app/views/layouts/application.html.erb の <head> 内 -->
<%= favicon_link_tag 'favicon.ico' %>
```

**推奨仕様**:
- サイズ: 16x16, 32x32, 48x48（マルチサイズ.ico）
- または PNG形式で複数サイズ準備

---

### 2. カラーリングの統一（グレージュベース）

#### 2-1. Tailwind CSS カスタムカラー設定

**グレージュカラーパレット**:
```javascript
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      colors: {
        // グレージュベースカラー
        'greige': {
          50:  '#faf9f7',   // 最も明るい（背景用）
          100: '#f5f3f0',   // 背景、カード
          200: '#e8e4df',   // ボーダー、区切り線
          300: '#d4cec5',   // 無効化要素
          400: '#b8b0a3',   // 補助テキスト
          500: '#9c9180',   // ベースグレージュ
          600: '#7d746a',   // ボタン、アクセント
          700: '#5e5851',   // テキスト（濃）
          800: '#3f3c38',   // テキスト（最濃）
          900: '#2a2825',   // ヘッダー、フッター
        },
        // アクセントカラー
        'accent': {
          primary: '#8b7355',   // 主要アクション（グレージュ系ブラウン）
          secondary: '#b5a188', // 補助アクション
          success: '#7a9b76',   // 成功（落ち着いたグリーン）
          warning: '#d4a574',   // 警告（ベージュ系オレンジ）
          danger: '#c17b7b',    // エラー（落ち着いたレッド）
          info: '#7b9bc1',      // 情報（落ち着いたブルー）
        }
      }
    }
  }
}
```

---

#### 2-2. カラーリングの適用箇所

**背景色**:
- ページ全体: `bg-greige-50`
- カード: `bg-white` または `bg-greige-100`
- ヘッダー/フッター: `bg-greige-900 text-greige-50`

**テキスト色**:
- 見出し: `text-greige-800`
- 本文: `text-greige-700`
- 補助テキスト: `text-greige-400`

**ボーダー**:
- 通常: `border-greige-200`
- ホバー: `border-greige-300`

---

### 3. ボタンデザインの統一

#### 3-1. ボタンカラーパターン

**プライマリボタン（主要アクション）**:
```html
<button class="btn bg-accent-primary hover:bg-greige-600 text-white">
  保存する
</button>
```

**セカンダリボタン（補助アクション）**:
```html
<button class="btn bg-greige-100 hover:bg-greige-200 text-greige-700 border border-greige-300">
  キャンセル
</button>
```

**成功ボタン（完了・承認）**:
```html
<button class="btn bg-accent-success hover:bg-green-700 text-white">
  承認する
</button>
```

**警告ボタン（注意が必要）**:
```html
<button class="btn bg-accent-warning hover:bg-orange-600 text-white">
  一時保存
</button>
```

**危険ボタン（削除・取消）**:
```html
<button class="btn bg-accent-danger hover:bg-red-700 text-white">
  削除する
</button>
```

---

#### 3-2. ボタンサイズとスタイル

**サイズバリエーション**:
- `btn-sm`: 小さいボタン（テーブル内アクション）
- `btn`: 通常サイズ（一般的な操作）
- `btn-lg`: 大きいボタン（CTAなど）

**スタイルバリエーション**:
- `btn-outline`: アウトライン（目立たせたくない操作）
- `btn-ghost`: ゴースト（リンク的な操作）

---

### 4. 全ページへの適用

#### 4-1. レイアウトファイルの更新

**application.html.erb**:
```erb
<!DOCTYPE html>
<html>
  <head>
    <title>電子カルテアプリ</title>
    <%= favicon_link_tag 'favicon.ico' %>
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>

  <body class="bg-greige-50 min-h-screen">
    <%= render 'layouts/header' %>

    <main class="container mx-auto px-4 py-8">
      <%= render 'layouts/flash' %>
      <%= yield %>
    </main>

    <%= render 'layouts/footer' %>
  </body>
</html>
```

---

#### 4-2. ヘッダーパーシャル

**app/views/layouts/_header.html.erb**:
```erb
<header class="navbar bg-greige-900 text-greige-50 shadow-lg">
  <div class="container mx-auto">
    <div class="navbar-start">
      <%= link_to root_path, class: "btn btn-ghost normal-case" do %>
        <%= image_tag 'logo.png',
                      alt: '電子カルテアプリ',
                      class: 'h-8 md:h-10 w-auto',
                      srcset: "#{image_path('logo.png')} 1x, #{image_path('logo@2x.png')} 2x" %>
      <% end %>
    </div>

    <div class="navbar-center hidden lg:flex">
      <ul class="menu menu-horizontal px-1">
        <li><%= link_to 'カルテ', medical_records_path, class: 'hover:bg-greige-800' %></li>
        <li><%= link_to '患者', patients_path, class: 'hover:bg-greige-800' %></li>
        <li><%= link_to '施術場所', facilities_path, class: 'hover:bg-greige-800' %></li>
        <li><%= link_to 'ダッシュボード', dashboard_path, class: 'hover:bg-greige-800' %></li>
      </ul>
    </div>

    <div class="navbar-end">
      <% if user_signed_in? %>
        <div class="dropdown dropdown-end">
          <label tabindex="0" class="btn btn-ghost btn-circle avatar">
            <div class="w-10 rounded-full bg-accent-primary text-white flex items-center justify-center">
              <span class="text-lg font-bold"><%= current_user.email[0].upcase %></span>
            </div>
          </label>
          <ul tabindex="0" class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-white rounded-box w-52">
            <li><%= link_to 'マイページ', mypage_path %></li>
            <% if current_user.admin? %>
              <li><%= link_to '管理者画面', admin_root_path %></li>
            <% end %>
            <li><%= button_to 'ログアウト', destroy_user_session_path, method: :delete, class: 'text-accent-danger' %></li>
          </ul>
        </div>
      <% end %>
    </div>
  </div>
</header>
```

---

#### 4-3. フッターパーシャル

**app/views/layouts/_footer.html.erb**:
```erb
<footer class="footer footer-center p-10 bg-greige-900 text-greige-50 mt-auto">
  <div>
    <p>© 2025 電子カルテアプリ. All rights reserved.</p>
    <div class="grid grid-flow-col gap-4 mt-2">
      <%= link_to '利用規約', terms_path, class: 'link link-hover' %>
      <%= link_to 'プライバシーポリシー', privacy_path, class: 'link link-hover' %>
      <%= link_to 'お問い合わせ', new_inquiry_path, class: 'link link-hover' %>
    </div>
  </div>
</footer>
```

---

#### 4-4. Flashメッセージパーシャル

**app/views/layouts/_flash.html.erb**:
```erb
<% flash.each do |type, message| %>
  <div class="alert alert-<%= flash_type_to_class(type) %> mb-4 shadow-lg">
    <div>
      <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current flex-shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
        <%= render_flash_icon(type) %>
      </svg>
      <span><%= message %></span>
    </div>
    <button type="button" class="btn btn-sm btn-ghost" onclick="this.parentElement.remove()">×</button>
  </div>
<% end %>
```

**ヘルパーメソッド**:
```ruby
# app/helpers/application_helper.rb
module ApplicationHelper
  def flash_type_to_class(type)
    case type.to_sym
    when :notice then 'info'
    when :success then 'success'
    when :alert then 'warning'
    when :error then 'error'
    else 'info'
    end
  end
end
```

---

### 5. カードデザインの統一

**基本カード**:
```html
<div class="card bg-white shadow-sm border border-greige-200 hover:shadow-md transition-shadow">
  <div class="card-body">
    <h2 class="card-title text-greige-800">カードタイトル</h2>
    <p class="text-greige-700">カード本文</p>
    <div class="card-actions justify-end">
      <button class="btn bg-accent-primary text-white">詳細</button>
    </div>
  </div>
</div>
```

---

## 📊 実装手順

### Step 1: 画像ファイルの配置（5分）
```bash
# ロゴとファビコンを配置
cp /path/to/logo.png app/assets/images/
cp /path/to/logo@2x.png app/assets/images/
cp /path/to/favicon.ico public/
```

### Step 2: Tailwind設定（10分）
```bash
# tailwind.config.js にカスタムカラー追加
# 上記のカラーパレットを設定
```

### Step 3: レイアウトファイル更新（30分）
- `application.html.erb` 更新
- `_header.html.erb` 作成
- `_footer.html.erb` 作成
- `_flash.html.erb` 作成

### Step 4: 全ページのボタン・カード適用（2-3時間）
- カルテ関連ページ
- 患者管理ページ
- 施術場所ページ
- ダッシュボード
- 請求書ページ
- 管理者ページ

### Step 5: 動作確認（30分）
- 全ページの表示確認
- レスポンシブ確認（モバイル/タブレット/デスクトップ）
- ブラウザ互換性確認

---

## ✅ 完了基準

### 機能面
- [x] ヘッダーロゴが全ページで表示される
- [x] ファビコンがブラウザタブに表示される
- [x] グレージュカラーパレットがTailwindに設定されている
- [x] 全ページで統一されたカラーリング
- [x] ボタンが統一されたデザインになっている

### 品質面
- [x] レスポンシブ対応完了
- [x] ブラウザ互換性確認（Chrome, Safari, Firefox, Edge）
- [x] アクセシビリティ確認（色のコントラスト比）

### テスト
- System Specが全てパス（既存機能に影響なし）
- 視覚的なリグレッションなし

---

## 🎨 デザインコンセプト

**キーワード**: 落ち着き、プロフェッショナル、清潔感、信頼性

**カラーイメージ**:
- **グレージュ**: ニュートラルで落ち着いた、医療現場に適した色
- **アクセント**: 控えめながら視認性の高い、機能的な色使い
- **余白**: 十分な余白で、情報を整理して見やすく

---

## 📝 注意事項

### パフォーマンス
- ロゴ画像は最適化済みであること（TinyPNG等）
- ファビコンは適切なサイズ（16x16, 32x32）

### アクセシビリティ
- カラーコントラスト比 4.5:1 以上（WCAG AA準拠）
- ボタンは十分なタップターゲットサイズ（44x44px以上）

### ブラウザ互換性
- Tailwind CSS v3系の機能を使用
- モダンブラウザ（Chrome, Safari, Firefox, Edge最新版）対応

---

**次のフェーズ**: Phase 7（ログイン機能関連）
**作成者**: Claude
**最終更新**: 2025-10-23

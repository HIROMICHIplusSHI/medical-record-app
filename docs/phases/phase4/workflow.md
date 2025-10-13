# Phase 4: ワークフロー・PRプロセス

**バージョン**: 1.0
**作成日**: 2025-10-13

---

## 1. ブランチ戦略

### 1.1 基本方針

```
main (保護ブランチ)
  └─ feature/p4-XX-XXXX (機能ブランチ)
```

- **main**: 常にデプロイ可能な状態を維持
- **feature/p4-XX-XXXX**: Phase 4の各機能ごとにブランチ作成

### 1.2 ブランチ命名規則

```
feature/p4-[番号]-[機能名]
```

**例**:
- `feature/p4-01-header-navigation` - ヘッダー・ナビゲーション
- `feature/p4-02-my-account` - マイアカウント画面
- `feature/p4-03-dashboard-ui` - ダッシュボードUI改善

### 1.3 ブランチの作成

```bash
# mainブランチを最新化
git checkout main
git pull origin main

# 機能ブランチを作成
git checkout -b feature/p4-01-header-navigation

# 作業開始
```

---

## 2. 開発フロー

### 2.1 開発サイクル

```
1. ブランチ作成
    ↓
2. 開発・テスト（TDD）
    ↓
3. コミット（小さな単位で）
    ↓
4. ローカルテスト実行
    ↓
5. プッシュ
    ↓
6. PR作成（Draft）
    ↓
7. セルフレビュー・CI確認
    ↓
8. Ready for Review
    ↓
9. レビュー・修正
    ↓
10. マージ
```

### 2.2 TDD サイクル

Phase 4でも引き続きTDDアプローチを採用します:

```ruby
# 1. Red: テスト作成（失敗する）
# spec/system/header_navigation_spec.rb
RSpec.describe 'Header Navigation', type: :system do
  it 'displays header on all pages' do
    visit root_path
    expect(page).to have_selector('header')
    expect(page).to have_link('カルテ')
  end
end

# 2. Green: 最小限の実装（テストが通る）
# app/views/shared/_header.html.erb
<header>
  <%= link_to 'カルテ', medical_records_path %>
</header>

# 3. Refactor: リファクタリング（品質向上）
# - Tailwindクラスでスタイリング
# - パーシャルの整理
# - 重複コードの削除
```

### 2.3 コミットガイドライン

#### コミットメッセージ形式

```
[種別] 簡潔な説明（50文字以内）

詳細な説明（必要に応じて）
- 変更の理由
- 影響範囲
- 技術的な詳細

関連: #Issue番号
```

#### コミット種別

| 種別 | 用途 | 例 |
|------|------|-----|
| `feat` | 新機能追加 | `feat: ヘッダーコンポーネント追加` |
| `fix` | バグ修正 | `fix: モバイルメニューの表示崩れ修正` |
| `test` | テスト追加・修正 | `test: ヘッダーナビゲーションのSystemテスト追加` |
| `refactor` | リファクタリング | `refactor: ヘッダーコンポーネントを分割` |
| `style` | コードスタイル修正 | `style: RuboCop違反修正` |
| `docs` | ドキュメント更新 | `docs: Phase 4 overview更新` |
| `chore` | ビルド・設定変更 | `chore: importmap設定追加` |

#### コミット例

```bash
# 良い例
git commit -m "feat: デスクトップヘッダーナビゲーション実装

- 主要メニュー項目（カルテ、患者、施設）を表示
- 現在ページのハイライト表示機能追加
- Tailwind CSSでスタイリング

関連: #10"

# 悪い例（避けるべき）
git commit -m "update"
git commit -m "fix bug"
git commit -m "WIP"
```

---

## 3. プルリクエスト（PR）プロセス

### 3.1 PR作成タイミング

**Draft PR（早期作成推奨）**:
- 開発開始時点で作成してOK
- CI結果を確認しながら開発可能
- 進捗を可視化できる

**Ready for Review**:
- 実装完了
- テスト追加済み
- ローカルで全テスト通過
- RuboCop違反なし
- セルフレビュー完了

### 3.2 PRテンプレート

```markdown
## 概要
[この PRで何を実現するか、簡潔に説明]

## 変更内容
- [ ] ヘッダーコンポーネント作成
- [ ] デスクトップナビゲーション実装
- [ ] モバイルハンバーガーメニュー実装
- [ ] Systemテスト追加

## スクリーンショット
### デスクトップ表示
[スクリーンショットまたは説明]

### モバイル表示
[スクリーンショットまたは説明]

## テスト
- [ ] RSpec全テスト通過
- [ ] RuboCop違反なし
- [ ] iPad Safari で動作確認
- [ ] iPhone Safari で動作確認
- [ ] Chrome デスクトップで動作確認

## レビュー観点
- [ ] デザイン仕様（`docs/08_screen_design.md`）に準拠しているか
- [ ] レスポンシブ対応は適切か
- [ ] アクセシビリティは考慮されているか
- [ ] パフォーマンスへの影響はないか

## 関連Issue・PR
- Phase 4 Overview: `docs/phases/phase4/overview.md`
- 関連PR: なし（初回PR）

## その他
[補足情報があれば記載]
```

### 3.3 PRレビューチェックリスト

#### 機能面
- [ ] 実装内容が要件を満たしているか
- [ ] エッジケースが考慮されているか
- [ ] エラーハンドリングは適切か

#### コード品質
- [ ] テストが追加されているか（80%以上カバレッジ維持）
- [ ] RuboCop違反がないか
- [ ] 命名規則が適切か
- [ ] 重複コードがないか

#### UI/UX
- [ ] デザイン仕様に準拠しているか
- [ ] レスポンシブ対応は適切か
- [ ] iPad/iPhoneで動作確認したか
- [ ] アクセシビリティは考慮されているか

#### パフォーマンス
- [ ] N+1クエリが発生していないか
- [ ] 不要なデータ取得がないか
- [ ] フロントエンドのレンダリングは最適か

#### ドキュメント
- [ ] 必要に応じてドキュメント更新したか
- [ ] コメントが適切に記載されているか

---

## 4. CI/CD設定

### 4.1 GitHub Actions

Phase 3で構築したCI設定を引き続き使用:

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v3

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2.2
          bundler-cache: true

      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install dependencies
        run: |
          bundle install
          yarn install

      - name: Setup database
        env:
          RAILS_ENV: test
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/test
        run: |
          bin/rails db:create
          bin/rails db:schema:load

      - name: Run RuboCop
        run: bundle exec rubocop

      - name: Run RSpec
        env:
          RAILS_ENV: test
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/test
        run: bundle exec rspec

      - name: Upload coverage
        uses: actions/upload-artifact@v3
        with:
          name: coverage
          path: coverage/
```

### 4.2 ローカルでのCI確認

PRを作成する前に、ローカルで以下を実行:

```bash
# 1. RuboCop実行
bundle exec rubocop

# 2. RSpec実行
bundle exec rspec

# 3. カバレッジ確認
open coverage/index.html

# 4. System テスト個別実行（必要に応じて）
bundle exec rspec spec/system/header_navigation_spec.rb
```

---

## 5. マージ戦略

### 5.1 マージ条件

以下すべてを満たした場合にマージ可能:

- [ ] CI（GitHub Actions）が全て通過
- [ ] レビュー承認（セルフレビュー完了）
- [ ] コンフリクトなし
- [ ] テストカバレッジ 80%以上維持
- [ ] RuboCop違反なし

### 5.2 マージ方法

**Squash and Merge（推奨）**:
- 複数のコミットを1つにまとめてマージ
- コミット履歴がクリーンになる
- PRごとに1コミットとなり、履歴が追いやすい

```
Squash and Merge メッセージ例:

Phase 4-01: ヘッダー・ナビゲーション実装 (#10)

- ヘッダーコンポーネント作成
- デスクトップナビゲーション実装
- モバイルハンバーガーメニュー実装
- ユーザードロップダウン実装
- Systemテスト追加
```

### 5.3 マージ後の対応

```bash
# mainブランチを最新化
git checkout main
git pull origin main

# マージ済みブランチを削除（ローカル）
git branch -d feature/p4-01-header-navigation

# 次の機能開発へ
git checkout -b feature/p4-02-my-account
```

---

## 6. トラブルシューティング

### 6.1 コンフリクト発生時

```bash
# mainブランチの最新を取得
git checkout main
git pull origin main

# 機能ブランチにマージ
git checkout feature/p4-01-header-navigation
git merge main

# コンフリクト解消後
git add .
git commit -m "fix: mainブランチとのコンフリクト解消"
git push origin feature/p4-01-header-navigation
```

### 6.2 CI失敗時

**RuboCop違反**:
```bash
# 自動修正
bundle exec rubocop -A

# 修正内容確認後コミット
git add .
git commit -m "style: RuboCop違反修正"
git push
```

**RSpec失敗**:
```bash
# 失敗したテストのみ実行
bundle exec rspec spec/system/header_navigation_spec.rb

# デバッグモードで実行
bundle exec rspec spec/system/header_navigation_spec.rb --format documentation

# 修正後、全テスト実行
bundle exec rspec
```

### 6.3 iPad/Safari固有の問題

Phase 3で対応済みのTom Selectパターンを参照:

```javascript
// app/javascript/controllers/tom_select_controller.js
// iPad/Safari で動作するドロップダウン実装例
import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

export default class extends Controller {
  connect() {
    new TomSelect(this.element, {
      create: false,
      sortField: { field: "text", direction: "asc" }
    })
  }
}
```

---

## 7. Phase 4固有の注意事項

### 7.1 レスポンシブ対応

**Tailwindブレークポイント**:
```css
/* デフォルト: モバイルファースト */
.class { /* < 768px */ }

/* タブレット以上 */
@media (min-width: 768px) { .md:class }

/* デスクトップ以上 */
@media (min-width: 1024px) { .lg:class }
```

**実装例**:
```erb
<!-- モバイル: ハンバーガーメニュー表示 -->
<button class="md:hidden">≡</button>

<!-- タブレット以上: 通常メニュー表示 -->
<nav class="hidden md:flex">...</nav>
```

### 7.2 Stimulus.js活用

Phase 3で実装済みのパターンを活用:

```javascript
// app/javascript/controllers/dropdown_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  toggle() {
    this.menuTarget.classList.toggle("hidden")
  }

  // クリック外でメニューを閉じる
  hide(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add("hidden")
    }
  }
}
```

### 7.3 iPad実機テスト

開発中は定期的にiPad実機で確認:

```bash
# ローカルサーバーを起動
rails s -b 0.0.0.0

# iPadからアクセス
# http://[あなたのローカルIP]:3000
```

**確認項目**:
- [ ] タップ操作が正常に動作するか
- [ ] ドロップダウンメニューが開閉するか
- [ ] フォーム入力が可能か
- [ ] 画面回転時の表示が適切か

---

## 8. ドキュメント更新フロー

### 8.1 更新対象ドキュメント

各PRマージ時に以下を更新:

1. **`docs/phases/phase4/progress.md`** - PR履歴追加
2. **`docs/phases/phase4/overview.md`** - マイルストーン更新（必要に応じて）
3. **`README.md`** - 機能追加時のみ

### 8.2 更新タイミング

- PR作成時: Draft PRとして概要記載
- マージ時: 完了ステータス更新
- Phase完了時: Phase 4 Overview更新

---

## 9. 参考リソース

### 9.1 Phase 3の実装パターン

- **Tom Select導入**: `docs/phases/phase3/progress.md` (Phase 3-04)
- **Stimulus.js活用**: `app/javascript/controllers/cost_items_controller.js`
- **Systemテスト**: `spec/system/medical_records_spec.rb`

### 9.2 外部リソース

- [Tailwind CSS ドキュメント](https://tailwindcss.com/docs)
- [Stimulus.js ハンドブック](https://stimulus.hotwired.dev/handbook/introduction)
- [Turbo リファレンス](https://turbo.hotwired.dev/reference/drive)

---

**次のステップ**: [`progress.md`](./progress.md) でPhase 4の進捗を追跡

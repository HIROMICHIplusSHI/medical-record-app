# テスト戦略とE2Eテストガイド

**プロジェクト名**: フリーランスアートメイク施術者向け電子カルテアプリ
**作成日**: 2025-10-12
**バージョン**: 1.0

---

## 1. はじめに

### 1.1 なぜE2EテストとSystemSpecが重要か

**前回プロジェクトからの教訓:**
- 開発環境では動作するが本番環境でJavaScriptが動かない
- Turbo/Stimulusの挙動が環境によって異なる
- アセットプリコンパイル後の動作確認不足

**このプロジェクトで特に重要な理由:**
1. **Hotwire（Turbo + Stimulus）を使用**: JavaScript込みの動作確認必須
2. **動的フォーム**: コスト項目の追加・削除がJavaScriptで実装
3. **画像アップロード**: Active Storage + Turboの組み合わせ
4. **実用アプリ**: 実際のユーザーが使うため品質保証が重要

---

## 2. テストピラミッド戦略

### 2.1 テストの種類と比率

```
        /\
       /  \  ← E2E/SystemSpec (10%)
      /----\    重要なユーザーフロー
     /      \
    /--------\ ← 統合テスト (30%)
   /          \  Controller, Request Spec
  /------------\
 /--------------\ ← 単体テスト (60%)
/________________\ Model, Helper, Service
```

**目標カバレッジ:**
- **Model**: 90%以上（ビジネスロジックの中心）
- **Controller/Request**: 80%以上
- **SystemSpec**: 主要フロー100%（数は少なく、重要度高く）
- **全体**: 80%以上

### 2.2 テストレベルと責務

| テストレベル | 目的 | ツール | 実行速度 | カバー範囲 |
|-------------|------|--------|---------|----------|
| **Model Spec** | ビジネスロジック検証 | RSpec | 高速 | 60% |
| **Request Spec** | API・Controller動作 | RSpec | 高速 | 30% |
| **SystemSpec** | E2E・JavaScript込み | Capybara + Selenium/Cuprite | 低速 | 10% |

---

## 3. SystemSpec（E2Eテスト）セットアップ

### 3.1 必要なGem

```ruby
# Gemfile
group :test do
  gem "capybara", "~> 3.39"
  gem "selenium-webdriver", "~> 4.10"
  gem "cuprite", "~> 0.15" # 高速ヘッドレスドライバー
  gem "webdrivers", "~> 5.2" # Chrome/Chromedriverの自動管理
end
```

```bash
bundle install
```

### 3.2 RSpec SystemSpec 設定

**`spec/rails_helper.rb` に追加:**

```ruby
# spec/rails_helper.rb

require 'capybara/rspec'
require 'selenium/webdriver'
require 'capybara/cuprite'

RSpec.configure do |config|
  # ... 既存の設定 ...

  # SystemSpec用設定
  config.before(:each, type: :system) do
    driven_by :rack_test # デフォルトはJavaScript不要のテスト
  end

  # JavaScript使用テスト用（開発時・デバッグ用）
  config.before(:each, type: :system, js: true) do
    driven_by :selenium_chrome_headless
  end

  # CI環境用（高速）
  config.before(:each, type: :system, js: true) do
    if ENV['CI']
      driven_by :cuprite
    else
      driven_by :selenium_chrome_headless
    end
  end

  # スクリーンショット保存設定
  config.after(:each, type: :system, js: true) do |example|
    if example.exception
      meta = example.metadata
      filename = File.basename(meta[:file_path])
      line_number = meta[:line_number]
      screenshot_name = "screenshot-#{filename}-#{line_number}.png"
      screenshot_path = "tmp/screenshots/#{screenshot_name}"
      page.save_screenshot(screenshot_path)
      puts "Screenshot saved: #{screenshot_path}"
    end
  end
end

# Capybara設定
Capybara.configure do |config|
  config.default_max_wait_time = 5 # 最大待機時間（秒）
  config.server = :puma
  config.server_host = 'localhost'
  config.server_port = 3001 # テスト用ポート
end

# Selenium Chrome Headless設定
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--disable-gpu')
  options.add_argument('--window-size=1920,1080')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

# Cuprite設定（CI環境用）
Capybara.register_driver :cuprite do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [1920, 1080],
    browser_options: { 'no-sandbox': nil },
    inspector: true,
    headless: true
  )
end
```

### 3.3 ディレクトリ作成

```bash
mkdir -p spec/system
mkdir -p tmp/screenshots
```

---

## 4. SystemSpec実装ガイド

### 4.1 基本的なSystemSpecの書き方

#### 例1: ログインフロー

```ruby
# spec/system/user_authentication_spec.rb
require 'rails_helper'

RSpec.describe 'User Authentication', type: :system do
  let(:user) { create(:user, email: 'test@example.com', password: 'password') }

  describe 'ログイン機能' do
    it 'メール/パスワードでログインできる' do
      visit root_path
      click_link 'ログイン'

      fill_in 'メールアドレス', with: user.email
      fill_in 'パスワード', with: 'password'
      click_button 'ログイン'

      expect(page).to have_content('ログインしました')
      expect(page).to have_current_path(dashboard_path)
    end

    it '誤ったパスワードでログインできない' do
      visit new_user_session_path

      fill_in 'メールアドレス', with: user.email
      fill_in 'パスワード', with: 'wrong_password'
      click_button 'ログイン'

      expect(page).to have_content('メールアドレスまたはパスワードが違います')
    end
  end

  describe 'ログアウト機能' do
    before { sign_in user }

    it 'ログアウトできる' do
      visit dashboard_path
      click_link 'ログアウト'

      expect(page).to have_content('ログアウトしました')
      expect(page).to have_current_path(root_path)
    end
  end
end
```

#### 例2: カルテ作成（JavaScript込み）

```ruby
# spec/system/medical_records_spec.rb
require 'rails_helper'

RSpec.describe 'Medical Records', type: :system, js: true do
  let(:user) { create(:user) }
  let(:patient) { create(:patient, user: user) }
  let(:facility) { create(:facility, user: user) }
  let(:cost_sheet) { create(:cost_sheet, user: user, item_name: '眉毛アートメイク', standard_price: 50000) }

  before do
    sign_in user
    cost_sheet # 事前にコストシート作成
  end

  describe 'カルテ作成' do
    it '患者とコスト項目を選択してカルテを作成できる', :aggregate_failures do
      visit new_medical_record_path

      # 基本情報入力
      select patient.name, from: '患者'
      select facility.name, from: '施術場所'
      fill_in '施術日', with: Date.today

      # 施術内容入力
      fill_in '施術内容', with: '眉毛アートメイク施術'
      fill_in 'カウンセリング内容', with: '初回カウンセリング実施'

      # コスト項目追加（JavaScript動作）
      click_button 'コスト項目を追加'

      within('.cost-item:last-child') do
        select '眉毛アートメイク', from: 'コストシート'
        fill_in '単価', with: '50000'
        fill_in '数量', with: '1'
      end

      # 合計金額が自動計算されることを確認
      expect(page).to have_content('合計金額: ¥50,000')

      # 画像アップロード
      attach_file '写真', Rails.root.join('spec/fixtures/files/sample_image.jpg')

      # 保存
      click_button 'カルテを保存'

      # 保存成功の確認
      expect(page).to have_content('カルテを作成しました')
      expect(page).to have_content(patient.name)
      expect(page).to have_content(facility.name)
      expect(page).to have_content('¥50,000')
    end

    it 'コスト項目を複数追加・削除できる', :aggregate_failures do
      visit new_medical_record_path

      select patient.name, from: '患者'
      select facility.name, from: '施術場所'
      fill_in '施術日', with: Date.today

      # 1つ目のコスト項目追加
      click_button 'コスト項目を追加'
      within('.cost-item:nth-child(1)') do
        select '眉毛アートメイク', from: 'コストシート'
        fill_in '単価', with: '50000'
      end

      # 2つ目のコスト項目追加
      click_button 'コスト項目を追加'
      within('.cost-item:nth-child(2)') do
        fill_in '項目名', with: '麻酔代'
        fill_in '単価', with: '5000'
      end

      # 合計金額確認
      expect(page).to have_content('合計金額: ¥55,000')

      # 1つ目を削除
      within('.cost-item:nth-child(1)') do
        click_button '削除'
      end

      # 合計金額が更新されることを確認
      expect(page).to have_content('合計金額: ¥5,000')
    end
  end

  describe 'カルテ編集' do
    let(:medical_record) { create(:medical_record, user: user, patient: patient, facility: facility) }

    it 'カルテを編集できる' do
      visit edit_medical_record_path(medical_record)

      fill_in '施術内容', with: '更新された施術内容'
      click_button '更新'

      expect(page).to have_content('カルテを更新しました')
      expect(page).to have_content('更新された施術内容')
    end
  end
end
```

#### 例3: 検索・フィルタリング（Turbo Frame）

```ruby
# spec/system/medical_records_search_spec.rb
require 'rails_helper'

RSpec.describe 'Medical Records Search', type: :system, js: true do
  let(:user) { create(:user) }
  let(:patient1) { create(:patient, user: user, name: '田中花子') }
  let(:patient2) { create(:patient, user: user, name: '佐藤美咲') }
  let(:facility1) { create(:facility, user: user, name: '〇〇クリニック') }
  let(:facility2) { create(:facility, user: user, name: '△△病院') }

  before do
    sign_in user
    create(:medical_record, user: user, patient: patient1, facility: facility1, treatment_date: Date.today)
    create(:medical_record, user: user, patient: patient2, facility: facility2, treatment_date: 1.week.ago)
  end

  describe '検索機能' do
    it '患者名で検索できる' do
      visit medical_records_path

      fill_in '患者名', with: '田中'
      click_button '検索'

      # Turbo Frameの更新を待つ
      expect(page).to have_content('田中花子')
      expect(page).not_to have_content('佐藤美咲')
    end

    it '施術場所で絞り込みできる' do
      visit medical_records_path

      select '〇〇クリニック', from: '施術場所'
      click_button '検索'

      expect(page).to have_content('〇〇クリニック')
      expect(page).not_to have_content('△△病院')
    end

    it '日付範囲で絞り込みできる' do
      visit medical_records_path

      fill_in '開始日', with: Date.today
      fill_in '終了日', with: Date.today
      click_button '検索'

      expect(page).to have_content('田中花子')
      expect(page).not_to have_content('佐藤美咲')
    end
  end
end
```

#### 例4: 請求書生成とPDFダウンロード

```ruby
# spec/system/invoices_spec.rb
require 'rails_helper'

RSpec.describe 'Invoices', type: :system, js: true do
  let(:user) { create(:user) }
  let(:facility) { create(:facility, user: user) }
  let(:patient) { create(:patient, user: user) }

  before do
    sign_in user
    # 今月の施術記録を3件作成
    3.times do
      create(:medical_record,
             user: user,
             patient: patient,
             facility: facility,
             treatment_date: Date.today,
             total_amount: 50000)
    end
  end

  describe '請求書生成' do
    it '施術場所と月を指定して請求書を生成できる' do
      visit invoices_path

      click_link '請求書を生成'

      select facility.name, from: '施術場所'
      select Date.today.year, from: '年'
      select Date.today.month, from: '月'

      click_button '生成'

      expect(page).to have_content('請求書を生成しました')
      expect(page).to have_content(facility.name)
      expect(page).to have_content('¥150,000') # 50,000 × 3
    end

    it '請求書をPDFでダウンロードできる' do
      invoice = create(:invoice, user: user, facility: facility, total_amount: 150000)

      visit invoice_path(invoice)

      click_link 'PDFダウンロード'

      # PDFダウンロードの確認（ヘッダーチェック）
      # ※ 実際のファイル内容検証はRequest Specで行う
      expect(page.response_headers['Content-Type']).to include('application/pdf')
    end
  end
end
```

---

## 5. SystemSpecベストプラクティス

### 5.1 書き方のルール

#### ✅ Good: 明確で読みやすいテスト

```ruby
it 'ユーザーが新しいカルテを作成できる' do
  visit new_medical_record_path

  fill_in '患者名', with: patient.name
  fill_in '施術日', with: Date.today
  click_button '保存'

  expect(page).to have_content('カルテを作成しました')
end
```

#### ❌ Bad: 曖昧で複雑すぎるテスト

```ruby
it 'works' do
  visit '/'
  click_link 'foo'
  fill_in 'bar', with: 'baz'
  click_button 'submit'
  expect(page).to have_content('success')
end
```

### 5.2 待機処理

#### Capybaraの自動待機を活用

```ruby
# ✅ Good: Capybaraが自動で要素を待つ
expect(page).to have_content('読み込み完了')

# ❌ Bad: 固定sleep（不安定）
sleep 2
expect(page).to have_content('読み込み完了')
```

#### 明示的な待機が必要な場合

```ruby
# Turbo Frameの更新を待つ
expect(page).to have_css('turbo-frame#records[complete]')

# JavaScriptの処理完了を待つ
expect(page).to have_css('.cost-item', count: 2)
```

### 5.3 セレクタの選び方

#### 優先順位

1. **data-testid属性**（最優先）
2. **セマンティックなラベル**
3. **CSS class/id**（最終手段）

```ruby
# ✅ Best: data-testid
find('[data-testid="add-cost-item-btn"]').click

# ✅ Good: ラベル
click_button 'コスト項目を追加'

# ⚠️ OK: CSS（変更に弱い）
find('.btn-add-cost').click
```

**Viewに追加:**

```erb
<button data-testid="add-cost-item-btn" class="btn-primary">
  コスト項目を追加
</button>
```

### 5.4 テストデータの準備

#### FactoryBotの活用

```ruby
# spec/factories/medical_records.rb
FactoryBot.define do
  factory :medical_record do
    user
    patient
    facility
    treatment_date { Date.today }
    treatment_content { 'アートメイク施術' }
    total_amount { 50000 }

    trait :with_cost_items do
      after(:create) do |record|
        create_list(:cost_item, 2, medical_record: record)
      end
    end

    trait :with_photos do
      after(:create) do |record|
        record.photos.attach(
          io: File.open(Rails.root.join('spec/fixtures/files/sample_image.jpg')),
          filename: 'sample_image.jpg',
          content_type: 'image/jpeg'
        )
      end
    end
  end
end
```

```ruby
# テストで使用
let(:medical_record) { create(:medical_record, :with_cost_items, :with_photos) }
```

---

## 6. デバッグ方法

### 6.1 スクリーンショット撮影

```ruby
# テスト中の任意のタイミング
save_screenshot('debug.png')

# 自動保存設定（rails_helper.rbで設定済み）
# 失敗時に自動でtmp/screenshots/に保存
```

### 6.2 ブラウザをヘッドレスモードから外す

```ruby
# spec/rails_helper.rb
config.before(:each, type: :system, js: true, debug: true) do
  driven_by :selenium_chrome # ヘッドレスなし
end
```

```ruby
# テストに :debug タグを追加
it 'デバッグしたいテスト', :debug do
  # ブラウザが表示される
end
```

### 6.3 pry-byebugでの一時停止

```ruby
it 'デバッグしたいテスト' do
  visit root_path
  binding.pry # ここで一時停止
  click_button '保存'
end
```

pryセッション内で:
```ruby
page.html # 現在のHTML取得
page.current_path # 現在のパス
save_screenshot('debug.png') # スクリーンショット
```

---

## 7. CI/CD統合

### 7.1 GitHub Actions 設定

**`.github/workflows/test.yml`:**

```yaml
name: Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test_db
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    env:
      RAILS_ENV: test
      DATABASE_URL: postgres://postgres:postgres@localhost:5432/test_db
      CI: true

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2.2
          bundler-cache: true

      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y libvips-dev

      - name: Setup Database
        run: |
          bundle exec rails db:create
          bundle exec rails db:schema:load

      - name: Run RSpec (Unit + Request)
        run: bundle exec rspec --tag ~system

      - name: Run SystemSpec
        run: bundle exec rspec --tag system

      - name: Upload screenshots (失敗時)
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: screenshots
          path: tmp/screenshots/

      - name: Upload coverage
        uses: actions/upload-artifact@v3
        with:
          name: coverage
          path: coverage/
```

### 7.2 デプロイ前の必須チェック

```bash
# ローカルでの最終確認
bundle exec rspec
bundle exec rubocop
bundle exec brakeman

# 本番環境に近い状態でSystemSpec実行
RAILS_ENV=production bundle exec rspec spec/system
```

---

## 8. テストすべき重要シナリオ（このプロジェクト）

### 8.1 Phase 1（MVP）

| シナリオ | 優先度 | JavaScript | 理由 |
|---------|--------|-----------|------|
| ログイン・ログアウト | 🔴 High | No | 基本機能 |
| Google OAuth ログイン | 🔴 High | Yes | 外部API連携 |
| カルテ作成（コスト項目追加） | 🔴 High | Yes | 最重要機能・JavaScript |
| 画像アップロード | 🔴 High | Yes | Active Storage + Turbo |
| カルテ検索・フィルタ | 🟡 Medium | Yes | Turbo Frame |
| 施術場所・患者 CRUD | 🟢 Low | No | 単純CRUD |

### 8.2 Phase 2（拡張機能）

| シナリオ | 優先度 | JavaScript | 理由 |
|---------|--------|-----------|------|
| 請求書生成 | 🔴 High | Yes | ビジネスロジック重要 |
| PDF ダウンロード | 🔴 High | No | 実ファイル生成確認 |
| 売上ダッシュボード | 🟡 Medium | No | 表示確認 |
| CSV エクスポート | 🟢 Low | No | 単純ダウンロード |

### 8.3 SystemSpec実装の優先順位

**Week 3-6（Phase 1）で作成:**
1. ログイン・ログアウト
2. カルテ作成（JavaScript込み）
3. 画像アップロード
4. カルテ検索

**Week 7-9（Phase 2）で作成:**
5. 請求書生成
6. PDFダウンロード

---

## 9. パフォーマンス最適化

### 9.1 SystemSpecの高速化

#### 並列実行（オプション）

```ruby
# Gemfile
gem 'parallel_tests', group: :test
```

```bash
# 並列実行
bundle exec parallel_rspec spec/
```

#### 不要なJavaScriptテストを減らす

```ruby
# JavaScript不要な場合は js: true を付けない
it 'シンプルな表示確認' do # js: true なし
  visit root_path
  expect(page).to have_content('Welcome')
end
```

### 9.2 データベースクリーンアップ戦略

```ruby
# spec/rails_helper.rb
config.use_transactional_fixtures = false

config.before(:each, type: :system) do
  DatabaseCleaner.strategy = :truncation # SystemSpecは truncation
end

config.before(:each) do |example|
  unless example.metadata[:type] == :system
    DatabaseCleaner.strategy = :transaction # 他は transaction（高速）
  end
end
```

---

## 10. チェックリスト

### 10.1 SystemSpec作成時

- [ ] テストシナリオが明確で分かりやすい
- [ ] `js: true` が必要かどうか判断済み
- [ ] FactoryBotでテストデータ準備
- [ ] `expect` で適切なアサーション
- [ ] スクリーンショットが失敗時に自動保存される設定
- [ ] CI環境でも実行可能

### 10.2 デプロイ前

- [ ] 全SystemSpecがパス
- [ ] 本番環境に近い設定でテスト実行
- [ ] スクリーンショットで動作確認
- [ ] PDF生成など実ファイル確認

---

## 11. トラブルシューティング

### 11.1 よくある問題

#### 問題1: Turbo Frameが更新されない

**症状:**
```ruby
# 検索後、結果が表示されない
fill_in '検索', with: 'test'
click_button '検索'
expect(page).to have_content('検索結果') # 失敗
```

**解決法:**
```ruby
# Turbo Frameの更新を明示的に待つ
fill_in '検索', with: 'test'
click_button '検索'
expect(page).to have_css('turbo-frame#search-results[complete]')
expect(page).to have_content('検索結果')
```

#### 問題2: 画像アップロードが失敗

**症状:**
```
Errno::ENOENT: No such file or directory @ rb_sysopen
```

**解決法:**
```ruby
# spec/fixtures/files/ にサンプル画像を配置
# spec/fixtures/files/sample_image.jpg

attach_file '写真', Rails.root.join('spec/fixtures/files/sample_image.jpg')
```

#### 問題3: JavaScriptエラーでテストが失敗

**症状:**
```
Element not found or not visible
```

**解決法:**
```ruby
# 要素が表示されるまで待機
expect(page).to have_css('.modal', visible: true)
within('.modal') do
  click_button '確認'
end
```

---

## 12. Phase 2 実装状況

### 12.1 実装済みのE2Eテスト環境

**実装日**: 2025-10-12

#### セットアップ内容

**1. Capybara + Cuprite設定**

`spec/support/capybara.rb`に以下を実装:
- Cuprite (ヘッドレスChrome) ドライバー設定
- ウィンドウサイズ: 1400x1400
- 環境変数対応 (`INSPECTOR`, `HEADLESS`)
- 失敗時スクリーンショット自動保存機能

**2. Warden Test Helpers設定**

`spec/support/warden.rb`に認証ヘルパーを追加:
- `login_as user` でシステムスペック内でのログイン対応
- テスト後の自動クリーンアップ (`Warden.test_reset!`)

**3. Rails Helper設定**

`spec/rails_helper.rb`を更新:
- `spec/support/**/*.rb`の自動読み込み有効化

#### 実装済みテストケース

**spec/system/patient_workflows_spec.rb**

最小限の重要フローをテスト:
```ruby
describe '基本的な患者管理フロー' do
  it 'ユーザーが患者を登録・閲覧・削除できる', js: true do
    # 患者一覧 → 新規登録 → 詳細表示 → 削除
  end
end
```

**テスト内容**:
1. 患者一覧ページにアクセス
2. 新規患者登録フォームで入力
3. 登録成功を確認
4. 一覧に表示されることを確認
5. 患者を削除
6. 削除成功を確認

**テスト結果**:
- System spec: 1 example, 0 failures (1.72秒)
- Full suite: 128 examples, 0 failures, 6 pending (2.29秒)

#### レスポンシブデザイン確認

Ferrum (Cuprite) を使用して以下のデバイスサイズで動作確認済み:
- **デスクトップ**: 1400x1000
- **タブレット (iPad相当)**: 768x1024
- **モバイル (iPhone相当)**: 375x667

全てのサイズでログイン画面が正常に表示されることを確認。

#### E2Eテスト戦略

**最小限アプローチを採用した理由**:
- Request Specsで詳細なCRUDテストは既に実装済み (29 examples passing)
- E2Eテストは重要なユーザーフロー (登録→閲覧→削除) のみに絞り込み
- 実行時間の最適化 (1.72秒)
- メンテナンス負荷の軽減

**今後の拡張予定**:
- Phase 2機能の追加時に対応するE2Eテストを追加
- 検索・ページネーション機能がmainブランチにマージされたらテスト追加

### 12.2 コード品質

**RuboCop対応状況**:
- 自動修正適用済み
- 1件の警告 (`page.save_screenshot`) は意図的な実装のため保持

---

## 13. 参考資料

### 13.1 公式ドキュメント

- **RSpec**: https://rspec.info/
- **Capybara**: https://github.com/teamcapybara/capybara
- **Cuprite**: https://github.com/rubycdp/cuprite
- **FactoryBot**: https://github.com/thoughtbot/factory_bot

### 13.2 参考記事

- [Hotwire + RSpecでのSystemSpec書き方](https://qiita.com/)
- [Capybara Cheat Sheet](https://devhints.io/capybara)
- [Testing Turbo with RSpec](https://evilmartians.com/)

---

**Document Version**: 1.1
**Last Updated**: 2025-10-12
**Next Review**: Phase 2完了時

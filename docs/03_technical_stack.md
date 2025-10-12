# 技術選定と開発環境セットアップガイド

**プロジェクト名**: フリーランス美容施術者向け電子カルテアプリ
**作成日**: 2025-10-12
**バージョン**: 1.0

---

## 1. 技術スタック

### 1.1 バックエンド

| 技術 | バージョン | 用途 | 選定理由 |
|-----|-----------|------|---------|
| **Ruby** | 3.2+ | プログラミング言語 | Rails 7との互換性、最新機能 |
| **Ruby on Rails** | 7.1+ | Webフレームワーク | 学習目標、高い生産性、豊富なGem |
| **PostgreSQL** | 14+ | データベース | 本番環境での安定性、JSON型対応 |
| **Puma** | 6.x | Webサーバー | Rails標準、高パフォーマンス |

### 1.2 フロントエンド

| 技術 | バージョン | 用途 | 選定理由 |
|-----|-----------|------|---------|
| **Hotwire** | 1.x | モダンなフロントエンド | Rails標準、SPA不要で高速 |
| - Turbo | 8.x | ページ遷移高速化 | フル Validation リロード不要 |
| - Stimulus | 3.x | JavaScript制御 | 軽量、Rails親和性高い |
| **Tailwind CSS** | 3.x | CSSフレームワーク | モダンなデザイン、カスタマイズ容易 |
| **ViewComponent** | 3.x | コンポーネント管理 | 再利用性向上、テスト容易 |

**代替案**: Bootstrap 5（より簡単だがカスタマイズ性低い）

### 1.3 認証・認可

| Gem | バージョン | 用途 | 選定理由 |
|-----|-----------|------|---------|
| **Devise** | 4.9+ | 認証システム | デファクトスタンダード、機能豊富 |
| **OmniAuth** | 2.x | OAuth認証 | ソーシャルログイン対応 |
| **omniauth-google-oauth2** | 1.x | Google OAuth | API要件を満たす |

### 1.4 ファイル管理

| 技術 | バージョン | 用途 | 選定理由 |
|-----|-----------|------|---------|
| **Active Storage** | Rails標準 | ファイルアップロード | Rails統合、S3互換対応 |
| **Cloudflare R2** | - | 画像ストレージ | **エグレス完全無料**、S3互換、10GB無料枠 |
| **ImageMagick** or **libvips** | - | 画像処理 | リサイズ、最適化 |
| **image_processing** | 1.x | 画像処理ラッパー | Active Storage連携 |

**代替案:**
- AWS S3（初年度5GB無料、エグレス有料）
- Backblaze B2（10GB無料、安定性重視）
- ローカルストレージ（開発環境のみ）

### 1.5 PDF生成

| Gem | バージョン | 用途 | 選定理由 |
|-----|-----------|------|---------|
| **Prawn** | 2.x | PDF生成 | 柔軟性高い、日本語対応 |
| **prawn-table** | 0.2+ | テーブル生成 | 請求書の表組み |

**代替案**: Wicked PDF（HTML→PDF変換、より簡単だが日本語フォント設定が必要）

### 1.6 テスト

| Gem | バージョン | 用途 | 選定理由 |
|-----|-----------|------|---------|
| **RSpec** | 3.12+ | テストフレームワーク | 表現力高い、デファクトスタンダード |
| **FactoryBot** | 6.x | テストデータ生成 | フィクスチャより柔軟 |
| **Faker** | 3.x | ダミーデータ生成 | 日本語対応 |
| **Capybara** | 3.x | E2E/SystemSpec | ブラウザ操作シミュレーション |
| **Selenium WebDriver** | 4.x | ブラウザ自動化 | 開発時のデバッグ、JavaScript対応 |
| **Cuprite** | 0.15+ | ヘッドレスドライバー | CI環境で高速実行、Seleniumより軽量 |
| **SimpleCov** | 0.22+ | カバレッジ計測 | 視覚的なレポート |
| **Database Cleaner** | 2.x | テストDB管理 | テスト間のデータクリーンアップ |

**テスト戦略の重要性:**
- 前回プロジェクトでの経験から、JavaScript（Hotwire）の環境差異問題対策として**SystemSpec（E2Eテスト）を必須化**
- 開発環境と本番環境の動作を保証
- 詳細は `docs/05_testing_strategy.md` を参照

### 1.7 コード品質

| Gem | バージョン | 用途 | 選定理由 |
|-----|-----------|------|---------|
| **RuboCop** | 1.x | コーディング規約 | 自動チェック、修正 |
| **rubocop-rails** | 2.x | Rails固有ルール | ベストプラクティス適用 |
| **rubocop-rspec** | 2.x | RSpec用ルール | テストコード品質向上 |
| **Brakeman** | 6.x | セキュリティ検査 | 脆弱性自動検出 |
| **Bullet** | 7.x | N+1クエリ検出 | パフォーマンス最適化 |

### 1.8 開発支援

| Gem | バージョン | 用途 | 選定理由 |
|-----|-----------|------|---------|
| **Pry** | 0.14+ | デバッガ | 強力なREPL |
| **pry-rails** | 0.3+ | Rails統合 | rails consoleで使用 |
| **better_errors** | 2.x | エラー画面改善 | 開発効率向上 |
| **binding_of_caller** | 1.x | エラー画面強化 | better_errors連携 |
| **annotate** | 3.x | スキーマ注釈 | モデルファイルにDB情報追記 |
| **rails-erd** | 1.x | ER図自動生成 | ドキュメント作成支援 |

### 1.9 外部API

| API | 用途 | 料金 | 備考 |
|-----|------|------|------|
| **Google OAuth 2.0** | ソーシャルログイン | 無料 | 個人利用範囲内 |
| **Cloudflare R2** | 画像ストレージ | 無料 | 10GB無料、エグレス完全無料 |
| **ImageOptim API** (検討中) | 画像最適化 | 無料枠あり | 1000枚/月まで無料 |

---

## 2. 開発環境セットアップ

### 2.1 必要なソフトウェア

#### 2.1.1 必須

| ソフトウェア | 推奨バージョン | インストール方法 |
|-------------|--------------|-----------------|
| **Ruby** | 3.2.2 | rbenv or asdf |
| **Rails** | 7.1.x | `gem install rails` |
| **PostgreSQL** | 14.x+ | Homebrew (Mac), apt (Linux) |
| **Node.js** | 18.x+ LTS | nodenv or nvm |
| **Yarn** | 1.22+ | npm install -g yarn |
| **Git** | 最新 | Homebrew or 公式サイト |

#### 2.1.2 推奨

| ソフトウェア | 用途 |
|-------------|------|
| **ImageMagick** or **libvips** | 画像処理 |
| **Redis** | Actioncable, Sidekiq（将来的に） |

### 2.2 macOS セットアップ手順

#### Step 1: Homebrew インストール

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### Step 2: rbenv + Ruby インストール

```bash
# rbenv インストール
brew install rbenv ruby-build

# rbenv 初期化（.zshrc or .bash_profileに追記）
echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
source ~/.zshrc

# Ruby 3.2.2 インストール
rbenv install 3.2.2
rbenv global 3.2.2

# 確認
ruby -v  # => ruby 3.2.2
```

#### Step 3: PostgreSQL インストール

```bash
# PostgreSQL インストール
brew install postgresql@14

# 起動
brew services start postgresql@14

# 確認
psql --version  # => psql (PostgreSQL) 14.x
```

#### Step 4: Node.js + Yarn インストール

```bash
# Node.js インストール（nvmを使用）
brew install nvm

# nvm初期化（.zshrcに追記）
echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
echo '[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"' >> ~/.zshrc
source ~/.zshrc

# Node.js LTS インストール
nvm install --lts
nvm use --lts

# Yarn インストール
npm install -g yarn

# 確認
node -v  # => v18.x.x
yarn -v  # => 1.22.x
```

#### Step 5: ImageMagick インストール

```bash
brew install imagemagick

# 確認
magick -version
```

#### Step 6: Git 設定

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

---

### 2.3 プロジェクト作成

#### Step 1: Railsアプリ作成

```bash
# プロジェクトディレクトリに移動
cd ~/Desktop/電子カルテ_app

# Railsアプリ作成（PostgreSQL, Hotwire, Tailwind CSS）
rails new . --database=postgresql --css=tailwind --javascript=importmap --skip-test

# または新規ディレクトリで作成する場合
# rails new medical_record_app --database=postgresql --css=tailwind --javascript=importmap --skip-test
```

**オプション説明:**
- `--database=postgresql`: PostgreSQL使用
- `--css=tailwind`: Tailwind CSS使用
- `--javascript=importmap`: Import maps使用（Webpacker不要）
- `--skip-test`: Minitestスキップ（RSpecを使用）

#### Step 2: データベース作成

```bash
# データベース作成
rails db:create

# 確認
rails db:migrate:status
```

#### Step 3: Gemfile 編集

`Gemfile` に以下を追加:

```ruby
# Gemfile

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.2"

# Rails標準
gem "rails", "~> 7.1.0"
gem "pg", "~> 1.5"
gem "puma", "~> 6.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "jbuilder"
gem "redis", "~> 5.0" # 将来的なActioncable用
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]
gem "bootsnap", require: false

# 認証
gem "devise", "~> 4.9"
gem "omniauth", "~> 2.1"
gem "omniauth-google-oauth2", "~> 1.1"
gem "omniauth-rails_csrf_protection", "~> 1.0" # CSRF対策

# ファイルアップロード・画像処理
gem "aws-sdk-s3", "~> 1.130", require: false # Cloudflare R2（S3互換）用
gem "image_processing", "~> 1.12"

# PDF生成
gem "prawn", "~> 2.4"
gem "prawn-table", "~> 0.2"

# UI
gem "view_component", "~> 3.0"

# ページネーション
gem "kaminari", "~> 1.2"

group :development, :test do
  # デバッグ
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
  gem "pry-rails", "~> 0.3"
  gem "pry-byebug", "~> 3.10"

  # テスト
  gem "rspec-rails", "~> 6.0"
  gem "factory_bot_rails", "~> 6.2"
  gem "faker", "~> 3.2"

  # コード品質
  gem "rubocop", "~> 1.50", require: false
  gem "rubocop-rails", "~> 2.19", require: false
  gem "rubocop-rspec", "~> 2.20", require: false
  gem "brakeman", "~> 6.0", require: false
end

group :development do
  gem "web-console"
  gem "better_errors", "~> 2.10"
  gem "binding_of_caller", "~> 1.0"
  gem "annotate", "~> 3.2"
  gem "rails-erd", "~> 1.7"
  gem "bullet", "~> 7.0"
end

group :test do
  gem "capybara", "~> 3.39"
  gem "selenium-webdriver", "~> 4.10"
  gem "cuprite", "~> 0.15" # 高速ヘッドレスドライバー（CI環境用）
  gem "webdrivers", "~> 5.2"
  gem "database_cleaner-active_record", "~> 2.1"
  gem "simplecov", "~> 0.22", require: false
end
```

#### Step 4: Bundle Install

```bash
bundle install
```

---

### 2.4 RSpec セットアップ

#### Step 1: RSpec インストール

```bash
rails generate rspec:install
```

生成されるファイル:
- `.rspec`
- `spec/spec_helper.rb`
- `spec/rails_helper.rb`

#### Step 2: RSpec 設定

`spec/rails_helper.rb` を編集:

```ruby
# spec/rails_helper.rb

require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'

# FactoryBot
require 'factory_bot_rails'

# Database Cleaner
require 'database_cleaner/active_record'

# SimpleCov（カバレッジ計測）
require 'simplecov'
SimpleCov.start 'rails' do
  add_filter '/bin/'
  add_filter '/db/'
  add_filter '/spec/'
  add_filter '/config/'
end

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = false # Database Cleaner使用のためfalse

  # FactoryBot
  config.include FactoryBot::Syntax::Methods

  # Devise
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::ControllerHelpers, type: :controller

  # Database Cleaner設定
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
```

`.rspec` に以下を追加:

```
--require spec_helper
--format documentation
--color
```

#### Step 3: RSpec動作確認

```bash
bundle exec rspec

# 出力例:
# No examples found.
# Finished in 0.00032 seconds (files took 1.2 seconds to load)
# 0 examples, 0 failures
```

---

### 2.5 Devise セットアップ

#### Step 1: Devise インストール

```bash
rails generate devise:install
```

#### Step 2: User モデル作成

```bash
rails generate devise User
```

#### Step 3: マイグレーション編集

`db/migrate/XXXXXX_devise_create_users.rb` を編集してOAuth用カラムを追加:

```ruby
class DeviseCreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      ## Database authenticatable
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## OmniAuth
      t.string :provider
      t.string :uid
      t.string :name

      t.timestamps null: false
    end

    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, [:provider, :uid],     unique: true
  end
end
```

#### Step 4: マイグレーション実行

```bash
rails db:migrate
```

#### Step 5: OmniAuth設定

`config/initializers/devise.rb` を編集:

```ruby
# config/initializers/devise.rb

Devise.setup do |config|
  # ... 既存の設定 ...

  # OmniAuth Google
  config.omniauth :google_oauth2,
                  ENV['GOOGLE_CLIENT_ID'],
                  ENV['GOOGLE_CLIENT_SECRET'],
                  scope: 'email,profile'
end
```

#### Step 6: 環境変数設定

`.env` ファイルを作成（`.gitignore`に追加済みか確認）:

```bash
# .env
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
```

`Gemfile` に `dotenv-rails` を追加:

```ruby
# Gemfile
group :development, :test do
  gem "dotenv-rails", "~> 2.8"
end
```

```bash
bundle install
```

---

### 2.6 Tailwind CSS セットアップ

既に `--css=tailwind` で生成されている場合はスキップ。

#### カスタマイズ（任意）

`app/assets/stylesheets/application.tailwind.css`:

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer components {
  .btn-primary {
    @apply bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700 transition;
  }

  .btn-secondary {
    @apply bg-gray-600 text-white px-4 py-2 rounded hover:bg-gray-700 transition;
  }

  .form-input {
    @apply border border-gray-300 rounded px-3 py-2 w-full focus:outline-none focus:ring-2 focus:ring-blue-500;
  }
}
```

---

### 2.7 Active Storage セットアップ

#### Step 1: インストール

```bash
rails active_storage:install
rails db:migrate
```

#### Step 2: ストレージ設定

`config/storage.yml`:

```yaml
# config/storage.yml

local:
  service: Disk
  root: <%= Rails.root.join("storage") %>

test:
  service: Disk
  root: <%= Rails.root.join("tmp/storage") %>

# Cloudflare R2（S3互換API）
cloudflare:
  service: S3
  access_key_id: <%= ENV['R2_ACCESS_KEY_ID'] %>
  secret_access_key: <%= ENV['R2_SECRET_ACCESS_KEY'] %>
  endpoint: <%= ENV['R2_ENDPOINT'] %> # 例: https://xxxx.r2.cloudflarestorage.com
  region: auto
  bucket: <%= ENV['R2_BUCKET_NAME'] %>
  force_path_style: true

# AWS S3（代替案）
# amazon:
#   service: S3
#   access_key_id: <%= ENV['AWS_ACCESS_KEY_ID'] %>
#   secret_access_key: <%= ENV['AWS_SECRET_ACCESS_KEY'] %>
#   region: ap-northeast-1
#   bucket: <%= ENV['S3_BUCKET_NAME'] %>
```

#### Step 3: 環境ごとの設定

```ruby
# config/environments/development.rb
config.active_storage.service = :local

# config/environments/test.rb
config.active_storage.service = :test

# config/environments/production.rb
config.active_storage.service = :cloudflare
```

---

### 2.8 Git リポジトリ初期化

#### Step 1: .gitignore確認

`.gitignore` に以下が含まれているか確認:

```
# .gitignore

# 環境変数
.env
.env.local

# データベース
/db/*.sqlite3
/db/*.sqlite3-*

# ログ
/log/*
/tmp/*
!/log/.keep
!/tmp/.keep

# ストレージ
/storage/*
!/storage/.keep
/tmp/storage/*
!/tmp/storage/.keep

# Node
/node_modules
/yarn-error.log
yarn-debug.log*

# IDE
/.idea
/.vscode
*.swp
*.swo
*~

# Mac
.DS_Store

# カバレッジ
/coverage/
```

#### Step 2: 初期コミット

```bash
git init
git add .
git commit -m "Initial commit: Rails 7 + PostgreSQL + Tailwind CSS + Devise"
```

#### Step 3: GitHub リポジトリ作成・プッシュ

```bash
# GitHubでリポジトリ作成後
git remote add origin https://github.com/your-username/medical-record-app.git
git branch -M main
git push -u origin main
```

---

## 3. 開発ワークフロー

### 3.1 日常の開発フロー

```bash
# 1. 最新のmainブランチをpull
git checkout main
git pull origin main

# 2. 機能ブランチ作成
git checkout -b feature/user-authentication

# 3. 開発
# コードを書く → テストを書く → テストを実行

# 4. RSpec実行
bundle exec rspec

# 5. RuboCop実行（コード規約チェック）
bundle exec rubocop -A  # -A: 自動修正

# 6. コミット
git add .
git commit -m "Add user authentication with Devise"

# 7. プッシュ
git push origin feature/user-authentication

# 8. GitHubでPull Request作成
```

### 3.2 TDD フロー

**Red → Green → Refactor**

1. **Red**: テストを書いて失敗させる
2. **Green**: 最小限のコードで成功させる
3. **Refactor**: コードをリファクタリング

```bash
# 1. モデルのテストファイル作成
touch spec/models/facility_spec.rb

# 2. テストを書く（Red）
# spec/models/facility_spec.rb にテストコードを書く

# 3. テスト実行（失敗を確認）
bundle exec rspec spec/models/facility_spec.rb

# 4. 実装（Green）
# app/models/facility.rb に実装

# 5. テスト実行（成功を確認）
bundle exec rspec spec/models/facility_spec.rb

# 6. リファクタリング（Refactor）
# コードを整理

# 7. 再度テスト実行
bundle exec rspec
```

### 3.3 データベースマイグレーション

```bash
# マイグレーションファイル生成
rails generate migration CreateFacilities

# マイグレーション実行
rails db:migrate

# ロールバック
rails db:rollback

# 特定のバージョンまでロールバック
rails db:migrate:down VERSION=20231001000000

# マイグレーションステータス確認
rails db:migrate:status

# シードデータ投入
rails db:seed

# DB再作成（開発時のみ！）
rails db:reset  # drop → create → migrate → seed
```

---

## 4. 開発ツール・コマンド

### 4.1 よく使うRailsコマンド

```bash
# サーバー起動
rails server
# または
rails s

# コンソール起動
rails console
# または
rails c

# ルート確認
rails routes

# モデル生成
rails generate model Facility name:string address:text user:references

# コントローラー生成
rails generate controller Facilities index show new create edit update destroy

# マイグレーション生成
rails generate migration AddUserIdToFacilities user:references

# タスク一覧
rails -T
```

### 4.2 RSpec コマンド

```bash
# 全テスト実行
bundle exec rspec

# 特定のファイルのテスト実行
bundle exec rspec spec/models/user_spec.rb

# 特定の行のテスト実行
bundle exec rspec spec/models/user_spec.rb:10

# カバレッジ計測
COVERAGE=true bundle exec rspec

# フォーマットを変更
bundle exec rspec --format documentation

# 失敗したテストのみ再実行
bundle exec rspec --only-failures
```

### 4.3 RuboCop コマンド

```bash
# チェック実行
bundle exec rubocop

# 自動修正
bundle exec rubocop -A

# 特定のファイルのみ
bundle exec rubocop app/models/user.rb

# 特定のルール無効化
bundle exec rubocop --except Layout/LineLength
```

### 4.4 Annotate コマンド

```bash
# モデルにスキーマ情報を追記
bundle exec annotate

# オプション付き
bundle exec annotate --models --routes --position before
```

### 4.5 ER図生成

```bash
# ER図生成（GraphViz必要）
brew install graphviz  # 初回のみ
bundle exec rails erd
```

---

## 5. デプロイ準備

### 5.1 本番環境用の設定

#### Step 1: 環境変数の準備

Renderなどのプラットフォームで以下の環境変数を設定:

```
RAILS_ENV=production
RAILS_MASTER_KEY=<config/master.keyの内容>
DATABASE_URL=<RenderのPostgreSQL URL>
R2_ACCESS_KEY_ID=<Cloudflare R2 Access Key>
R2_SECRET_ACCESS_KEY=<Cloudflare R2 Secret Key>
R2_ENDPOINT=<Cloudflare R2 Endpoint URL>
R2_BUCKET_NAME=<R2バケット名>
GOOGLE_CLIENT_ID=<Google Client ID>
GOOGLE_CLIENT_SECRET=<Google Client Secret>
```

#### Step 2: credentials編集

```bash
EDITOR="code --wait" rails credentials:edit
```

`config/credentials.yml.enc` に以下を追記:

```yaml
cloudflare:
  r2_access_key_id: your_r2_access_key
  r2_secret_access_key: your_r2_secret_key
  r2_endpoint: your_r2_endpoint
  r2_bucket: your_r2_bucket_name

google:
  client_id: your_client_id
  client_secret: your_client_secret
```

#### Step 3: render.yaml 作成（Render用）

```yaml
# render.yaml
services:
  - type: web
    name: medical-record-app
    env: ruby
    buildCommand: "./bin/render-build.sh"
    startCommand: "bundle exec puma -C config/puma.rb"
    envVars:
      - key: RAILS_MASTER_KEY
        sync: false
      - key: DATABASE_URL
        fromDatabase:
          name: medical-record-db
          property: connectionString

databases:
  - name: medical-record-db
    databaseName: medical_record_production
    user: medical_record_user
```

#### Step 4: ビルドスクリプト作成

```bash
#!/usr/bin/env bash
# bin/render-build.sh

set -o errexit

bundle install
bundle exec rails assets:precompile
bundle exec rails assets:clean
bundle exec rails db:migrate
```

```bash
chmod +x bin/render-build.sh
```

---

## 6. トラブルシューティング

### 6.1 よくある問題と解決法

#### PostgreSQL接続エラー

**エラー**: `FATAL: role "postgres" does not exist`

**解決法**:
```bash
# PostgreSQLユーザー作成
createuser -s postgres

# または config/database.yml でユーザー名を変更
```

#### ImageMagick/libvips エラー

**エラー**: `No such file or directory @ rb_sysopen - identify`

**解決法**:
```bash
brew install imagemagick
# または
brew install vips
```

#### Yarn/Node.jsエラー

**エラー**: `Yarn executable was not detected in the system`

**解決法**:
```bash
npm install -g yarn
# または
corepack enable
```

#### RSpec実行時のエラー

**エラー**: `Spring is running in production mode`

**解決法**:
```bash
bin/spring stop
bundle exec rspec
```

---

## 7. 推奨エディタ設定（VS Code）

### 7.1 拡張機能

- **Ruby**: Peng Lv
- **Ruby Solargraph**: castwide
- **Rails**: bung87
- **ERB Formatter/Beautify**: aliariff
- **Tailwind CSS IntelliSense**: Bradlc
- **GitLens**: GitKraken

### 7.2 settings.json

```json
{
  "editor.formatOnSave": true,
  "ruby.format": "rubocop",
  "ruby.useBundler": true,
  "ruby.lint": {
    "rubocop": true
  },
  "files.associations": {
    "*.html.erb": "erb"
  }
}
```

---

## 8. 参考資料

### 8.1 公式ドキュメント

- **Rails公式ガイド（日本語）**: https://railsguides.jp/
- **Devise**: https://github.com/heartcombo/devise
- **Hotwire**: https://hotwired.dev/
- **Tailwind CSS**: https://tailwindcss.com/docs
- **RSpec**: https://rspec.info/
- **Prawn**: https://prawnpdf.org/docs/

### 8.2 学習リソース

- **Rails Tutorial（日本語）**: https://railstutorial.jp/
- **RSpec Book**: https://leanpub.com/everydayrailsrspec-jp
- **Hotwire Handbook**: https://hotwire.dev/handbook

---

**Document Version**: 1.0
**Last Updated**: 2025-10-12
**Next Review**: 開発開始時

source 'https://rubygems.org'

ruby '3.2.9'

# Rails標準
gem 'bootsnap', require: false
gem 'importmap-rails'
gem 'jbuilder'
gem 'pg', '~> 1.1'
gem 'puma', '>= 5.0'
gem 'rails', '~> 7.2.0'
gem 'redis', '~> 5.0' # 将来的なActioncable用
gem 'sprockets-rails'
gem 'stimulus-rails'
gem 'tailwindcss-rails'
gem 'turbo-rails'
gem 'tzinfo-data', platforms: %i[windows jruby]

# 認証
gem 'devise', '~> 4.9'
gem 'omniauth', '~> 2.1'
gem 'omniauth-google-oauth2', '~> 1.1'
gem 'omniauth-rails_csrf_protection', '~> 1.0'

# 認可
gem 'pundit', '~> 2.3'

# ファイルアップロード・画像処理
gem 'aws-sdk-s3', '~> 1.130', require: false # Cloudflare R2（S3互換）用
gem 'image_processing', '~> 1.12'

# PDF生成
gem 'prawn', '~> 2.4'
gem 'prawn-table', '~> 0.2'

# Markdownレンダリング
gem 'kramdown', '~> 2.4'

# UI
gem 'view_component', '~> 3.0'

# ページネーション
gem 'kaminari', '~> 1.2'

# 検索
gem 'ransack', '~> 4.0'

group :development, :test do
  # デバッグ
  gem 'debug', platforms: %i[mri windows]
  gem 'pry-byebug', '~> 3.10'
  gem 'pry-rails', '~> 0.3'

  # 環境変数
  gem 'dotenv-rails', '~> 2.8'

  # テスト
  gem 'factory_bot_rails', '~> 6.2'
  gem 'faker', '~> 3.2'
  gem 'rspec-rails', '~> 6.0'

  # コード品質
  gem 'brakeman', '~> 6.0', require: false
  gem 'rubocop', '~> 1.50', require: false
  gem 'rubocop-rails', '~> 2.19', require: false
  gem 'rubocop-rspec', '~> 2.20', require: false
end

group :development do
  gem 'annotate', '~> 3.2'
  gem 'better_errors', '~> 2.10'
  gem 'binding_of_caller', '~> 1.0'
  gem 'bullet', '~> 7.0'
  gem 'rails-erd', '~> 1.7'
  gem 'web-console'
end

group :test do
  gem 'capybara', '~> 3.39'
  gem 'cuprite', '~> 0.15'
  gem 'database_cleaner-active_record', '~> 2.1'
  gem 'pdf-reader', '~> 2.12' # PDFコンテンツ検証用
  gem 'selenium-webdriver', '~> 4.10'
  gem 'shoulda-matchers', '~> 6.0'
  gem 'simplecov', '~> 0.22', require: false
  gem 'webdrivers', '~> 5.2'
end

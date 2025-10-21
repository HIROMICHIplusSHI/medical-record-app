# frozen_string_literal: true

require 'capybara/rspec'
require 'capybara/cuprite'

# Capybara基本設定
Capybara.default_max_wait_time = 10 # CI環境での待機時間を延長
Capybara.default_normalize_ws = true

# Cupriteドライバー設定（ヘッドレスChrome）
Capybara.register_driver(:cuprite) do |app|
  # CI環境でのChrome実行パス検出
  chrome_path = if ENV['CI']
                  # GitHub Actions環境
                  '/usr/bin/google-chrome-stable'
                elsif File.exist?('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome')
                  # macOS
                  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
                end

  options = {
    window_size: [1400, 1400],
    browser_options: {
      'no-sandbox': nil,
      'disable-gpu': nil,
      'disable-dev-shm-usage': nil, # CI環境での共有メモリ問題を回避
      'disable-software-rasterizer': nil, # CI環境でのレンダリング最適化
    },
    process_timeout: 120, # CI環境でのブラウザ起動タイムアウトを延長
    timeout: 30, # レスポンスタイムアウト
    inspector: ENV.fetch('INSPECTOR', nil),
    headless: !ENV['HEADLESS'].in?(%w[n 0 no false])
  }

  # CI環境の場合はChrome実行パスを明示的に指定
  options[:browser_path] = chrome_path if chrome_path

  Capybara::Cuprite::Driver.new(app, **options)
end

# JavaScriptを使うテストではCupriteドライバーを使用
Capybara.javascript_driver = :cuprite

# デフォルトドライバー設定
Capybara.default_driver = :rack_test # 通常のテストは高速なrack_testを使用
Capybara.javascript_driver = :cuprite # JavaScriptが必要なテストはCupriteを使用

RSpec.configure do |config|
  # システムテストの前後でスクリーンショットを保存
  config.before(:each, type: :system) do
    driven_by :cuprite
  end

  # テスト失敗時にスクリーンショットを保存
  config.after(:each, type: :system) do |example|
    if example.exception
      meta = example.metadata
      filename = File.basename(meta[:file_path])
      line_number = meta[:line_number]
      screenshot_name = "screenshot-#{filename}-#{line_number}.png"
      screenshot_path = "tmp/screenshots/#{screenshot_name}"
      page.save_screenshot(screenshot_path)
      puts "Screenshot saved to #{screenshot_path}"
    end
  end
end

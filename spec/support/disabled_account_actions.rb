# frozen_string_literal: true

# 新規登録・パスワード再設定・アカウント編集はデモ環境として常に無効化している（Issue #64）。
# ただし機能自体は実装済みのため、ロジックを検証するテストでは無効化を解除する。
#
# 使い方: describe/it に `account_actions_enabled: true` を付ける。
RSpec.configure do |config|
  config.around(:each, account_actions_enabled: true) do |example|
    DisabledAccountActions.enabled = false
    example.run
  ensure
    DisabledAccountActions.enabled = true
  end
end

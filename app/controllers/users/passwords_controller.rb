# frozen_string_literal: true

module Users
  # パスワード再設定はデモ環境では無効（Issue #64）。
  # 実装は Devise 標準のまま残し、入口だけを塞いでいる。
  class PasswordsController < Devise::PasswordsController
    include DisabledAccountActions
  end
end

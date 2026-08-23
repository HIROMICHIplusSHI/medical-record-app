# frozen_string_literal: true

# デモログイン（ワンクリックでデモ用アカウントにログインする機能）のドメインモデル。
#
# ポートフォリオ公開環境で、訪問者が資格情報を入力せずに機能を試せるようにするためのもの。
# 管理者アカウントは対象外（管理画面は公開しない方針。詳細は Issue #64）。
class DemoSession
  # デモ用アカウントのメールアドレス（seeds で作成される）
  DEMO_EMAIL = 'demo@example.com'

  class << self
    # デモログインを有効にするかどうか。既定は無効で、デモ環境でのみ明示的に有効化する。
    def enabled?
      ENV.fetch('DEMO_LOGIN_ENABLED', 'false') == 'true'
    end

    # ログインさせるデモユーザー。
    # admin ロールには決してログインさせないため、role: :user で明示的に絞り込む。
    def user
      User.find_by(email: DEMO_EMAIL, role: :user)
    end
  end
end

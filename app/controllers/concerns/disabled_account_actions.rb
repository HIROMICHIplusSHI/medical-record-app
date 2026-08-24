# frozen_string_literal: true

# ポートフォリオ公開用のデモ環境として、アカウント操作系の導線を無効化する（Issue #64）。
#
# 訪問者にはログイン画面の「デモアカウントでログイン」だけを使ってもらう方針のため、
# 新規登録・パスワード再設定・アカウント編集は画面上で押せないようにしたうえで、
# URL 直打ちに備えてサーバー側でも遮断する。
#
# 招待コード制の登録機能そのものは実装済みで、コードもテストも残してある
# （登録ロジックの検証は DisabledAccountActions.enabled = false にして行う）。
module DisabledAccountActions
  extend ActiveSupport::Concern

  MESSAGE = 'デモ環境のため、この機能は無効です。「デモアカウントでログイン」からお試しください。'

  # 無効化そのものを一時的に解除するためのフラグ。
  # 本番・開発では常に true。登録ロジックを検証するテストでのみ false にする。
  mattr_accessor :enabled, default: true

  included do
    before_action :redirect_disabled_account_action, if: -> { DisabledAccountActions.enabled }
  end

  private

  def redirect_disabled_account_action
    redirect_to disabled_account_action_redirect_path, notice: MESSAGE
  end

  def disabled_account_action_redirect_path
    user_signed_in? ? user_dashboard_path : new_user_session_path
  end
end

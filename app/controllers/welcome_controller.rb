# frozen_string_literal: true

# ログイン前のウェルカムページコントローラー
class WelcomeController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    # ログイン済みユーザーは適切なダッシュボードへリダイレクト
    return unless user_signed_in?

    redirect_to current_user.admin? ? admin_root_path : user_dashboard_path
  end
end

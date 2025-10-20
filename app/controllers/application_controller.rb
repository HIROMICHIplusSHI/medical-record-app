class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :authenticate_user!

  # Pundit未認可エラーハンドリング
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    flash[:alert] = 'この操作を実行する権限がありません。'
    fallback_path = current_user&.admin? ? admin_root_path : user_root_path
    redirect_to(request.referer || fallback_path)
  end

  # ログイン後のリダイレクト先をロール別に設定
  def after_sign_in_path_for(resource)
    if resource.admin?
      admin_root_path  # /admin
    else
      user_root_path   # /home (ユーザー専用)
    end
  end

  # ログアウト後のリダイレクト先
  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end
end
